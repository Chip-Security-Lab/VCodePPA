//SystemVerilog
module reg_out_shifter (
    input clk, reset_n,
    input req,    // request signal (mapped from valid)
    output ack,   // acknowledge signal (mapped from ready)
    input serial_in,
    output reg serial_out
);
    reg [3:0] shift;
    reg shift_0_reg;
    reg req_reg;
    
    assign ack = req_reg;
    
    always @(posedge clk) begin
        if (!reset_n) begin
            shift <= 4'b0000;
            shift_0_reg <= 1'b0;
            req_reg <= 1'b0;
        end
        else if (req) begin
            shift <= {serial_in, shift[3:1]};
            shift_0_reg <= shift[0];
            req_reg <= 1'b1;
        end
        else begin
            req_reg <= 1'b0;
        end
    end
    
    always @(*) begin
        serial_out = shift_0_reg;
    end
endmodule