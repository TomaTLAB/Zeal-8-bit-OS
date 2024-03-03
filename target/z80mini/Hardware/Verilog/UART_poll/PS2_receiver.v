module PS2_receiver (
	input clk, n_res,       // Тактовая частота 50 Мгц
	input ps2_clock,        // Пин, подключенный к проводу CLOCK с PS/2
	input ps2_data,         // Пин DATA
	input tim_clk,
	output reg       ps2_done,   // Устанавливается =1, если данные доступны
	output reg [7:0] ps2_out    // Принятый байт с PS/2
);

//	initial begin data = 8'h00; done = 1'b0; end

	reg         kbusy   = 1'b0;   // =1 Если идет прием данных с пина (шины) DATA
	reg         kdone   = 1'b0;   // =1 Прием сигнала завершен, "фантомный" регистр к `done`
	reg [1:0]   klatch  = 2'b00;  // Сдвиговый регистр для отслеживания позитивного и негативного фронта CLOCK
	reg [3:0]   kcount  = 1'b0;   // Номер такта CLOCK
	reg [9:0]   kin     = 1'b0;   // Сдвиговый регистр для приема данных с DATA
	reg [6:0]  kout    = 1'b0;   // Отсчет таймаута для "зависшего" приема данных в случае ошибки

//	always @(negedge clk) ps2_done <= kdone;

	always @(posedge clk) begin
		if (!n_res) begin
			ps2_out <= 8'h00;
			ps2_done <= 1'b0; 
		end else begin
			ps2_done <= kdone;
			kdone <= 1'b0;
			 // Процесс приема сигнала
			 if (kbusy) begin
				  // Позитивный фронт
				  if (klatch == 2'b01) begin
						// Завершающий такт
						if (kcount == 4'hA) begin
							 ps2_out    <= kin[8:1];
							 kbusy   <= 1'b0;
							 kdone   <= ^kin[9:1]; // =1 Если четность совпадает
						end
						kcount  <= kcount + 1'b1;
						kin     <= {ps2_data, kin[9:1]};
				  end
				  // Считать "зависший процесс"
				  kout <= (ps2_clock && tim_clk) ? kout + 1 : 1'b0;
				  // И если прошло более 204.8мкс, то перевести в состояние ожидания
				  if (&kout) kbusy <= 1'b0;
			 end else begin
				  // Обнаружен негативный фронт \__
				  if (klatch == 2'b10) begin
						kbusy   <= 1'b1; // Активировать прием данных
						kcount  <= 1'b0; // Сброс двух счетчиков в 0
						kout    <= 1'b0;
				  end
			 end
			 klatch <= {klatch[0], ps2_clock};
		end
	end
endmodule
