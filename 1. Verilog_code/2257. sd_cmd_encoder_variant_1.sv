//SystemVerilog
//IEEE 1364-2005 Verilog
module sd_cmd_encoder (
    input clk, cmd_en,
    input [5:0] cmd,
    input [31:0] arg,
    output reg cmd_out
);
    reg [47:0] shift_reg;
    reg [5:0] cnt;
    reg shift_active;
    
    // Pre-computed next bit moved before register
    // to reduce critical path delay
    wire [5:0] next_cnt = (cnt > 0) ? cnt - 1 : cnt;
    wire next_bit = shift_reg[cnt];
    
    always @(posedge clk) begin
        if (cmd_en) begin
            shift_reg <= {1'b0, cmd, arg, 7'h01};
            cnt <= 47;
            shift_active <= 1'b1;
            cmd_out <= 1'b1; // Default idle state
        end
        else if (shift_active) begin
            cmd_out <= next_bit;
            cnt <= next_cnt;
            
            if (cnt == 0)
                shift_active <= 1'b0;
        end
        else begin
            cmd_out <= 1'b1; // Return to idle state
        end
    end
endmodule