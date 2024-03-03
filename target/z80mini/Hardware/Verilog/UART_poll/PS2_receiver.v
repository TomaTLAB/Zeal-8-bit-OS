module PS2_receiver (		// За основу взят код попертый с "Лисьей норы" https://neurofox.ru/el/keybps2v2
	input clk, clk0, n_res,	// Тактовая частота 50 Мгц, Строб семплирования, Общий сброс
	input ps2_clock,			// CLOCK PS/2
	input ps2_data,         // DATA  PS/2
	input ps2_ack,				//	Сброс сигнала done
	input tim_clk,				// тактовая счетчика таймаута 925.925кГц
	output reg       ps2_done,   // Устанавливается =1, если данные доступны
	output reg [7:0] ps2_out    // Принятый байт с PS/2
);

	reg         kbusy;		// =1 Если идет прием данных с пина (шины) DATA
	reg [1:0]   klatch;	// Сдвиговый регистр для отслеживания позитивного и негативного фронта CLOCK
	reg [3:0]   kcount;	// Номер такта CLOCK
	reg [8:0]   kin;		// Сдвиговый регистр для приема данных с DATA
	reg [6:0]	tout;		// Отсчет таймаута для "зависшего" приема данных в случае ошибки

	always @(posedge clk) begin
		if (!n_res) begin
			ps2_out <= 8'h00;
			ps2_done <= 1'b0; 
			kbusy   <= 1'b0;
			klatch  <= 2'b00;
			kcount  <= 4'b0;
			kin     <= 9'b0;
			tout    <= 0;
		end else begin
			if (clk0) begin
				ps2_done <= ps2_ack ? 1'b0 : ps2_done;
				if (kbusy) begin // Процесс приема сигнала
					if (klatch == 2'b01) begin // Позитивный фронт __/
						if (kcount == 4'hA) begin // Завершающий такт
							 ps2_out    <= kin[7:0];
							 kbusy   	<= 1'b0;
							 ps2_done	<= ^kin[8:0]; // =1 Если четность совпадает
						end
						kcount  <= kcount + 1'b1;
						kin     <= {ps2_data, kin[8:1]};
					end
					tout <= (&klatch && tim_clk) ? tout + 1 : tout;	// Таймаут зависшего процесса
					//tout <= tim_clk ? tout + 1 : tout;	// Таймаут зависшего процесса
					if (&tout) kbusy <= 1'b0; // И если прошло более ~138мкс, то перевести в состояние ожидания (... а если зависло внизу?.. И надо ли оно вообще?.....)
				end else begin
					if (klatch == 2'b10) begin // Обнаружен негативный фронт \__
						kbusy   <= 1'b1; // Активировать прием данных
						kcount  <= 1'b0; // Сброс двух счетчиков в 0
						tout    <= 1'b0;
					end
				end
				klatch <= {klatch[0], ps2_clock};
			end
		end
	end
endmodule
