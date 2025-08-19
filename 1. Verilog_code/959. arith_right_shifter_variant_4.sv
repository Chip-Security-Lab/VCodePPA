//SystemVerilog
module arith_right_shifter (
    input CLK, RST_n,
    input [15:0] DATA_IN,
    input SHIFT,
    output reg [15:0] DATA_OUT
);
    reg [15:0] data_pre_shift;
    reg shift_reg;
    
    // Pre-compute shift result
    wire [15:0] shifted_data = {data_pre_shift[15], data_pre_shift[15:1]};
    
    // First register stage - store input and control signals
    always @(posedge CLK) begin
        case (RST_n)
            1'b0: begin
                data_pre_shift <= 16'h0000;
                shift_reg <= 1'b0;
            end
            1'b1: begin
                data_pre_shift <= DATA_IN;
                shift_reg <= SHIFT;
            end
        endcase
    end
    
    // Output register stage - select between shift or passthrough
    always @(posedge CLK) begin
        case ({RST_n, shift_reg})
            2'b00: DATA_OUT <= 16'h0000;
            2'b10: DATA_OUT <= data_pre_shift;
            2'b11: DATA_OUT <= shifted_data;
            default: DATA_OUT <= 16'h0000;
        endcase
    end
endmodule