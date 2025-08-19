//SystemVerilog
module phase_aligner #(parameter PHASES=4, DATA_W=8) (
    input clk, rst,
    input [DATA_W-1:0] phase_data_0,
    input [DATA_W-1:0] phase_data_1,
    input [DATA_W-1:0] phase_data_2,
    input [DATA_W-1:0] phase_data_3,
    output reg [DATA_W-1:0] aligned_data
);
    reg [DATA_W-1:0] phase_data_0_reg;
    reg [DATA_W-1:0] phase_data_1_reg;
    reg [DATA_W-1:0] phase_data_2_reg;
    reg [DATA_W-1:0] phase_data_3_reg;
    wire [DATA_W-1:0] xor_result;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase_data_0_reg <= 0;
            phase_data_1_reg <= 0;
            phase_data_2_reg <= 0;
            phase_data_3_reg <= 0;
        end else begin
            phase_data_0_reg <= phase_data_0;
            phase_data_1_reg <= phase_data_1;
            phase_data_2_reg <= phase_data_2;
            phase_data_3_reg <= phase_data_3;
        end
    end
    
    assign xor_result = phase_data_1_reg ^ phase_data_2_reg ^ phase_data_3_reg ^ phase_data_0_reg;
    
    always @(posedge clk)
        aligned_data <= xor_result;
endmodule