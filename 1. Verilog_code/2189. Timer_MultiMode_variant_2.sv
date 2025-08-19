//SystemVerilog
module Timer_MultiMode #(parameter MODE=0) (
    input clk, rst_n,
    input [7:0] period,
    output reg out
);
    reg [7:0] cnt;
    reg out_next;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'b0;
            out <= 1'b0;
        end
        else begin
            cnt <= cnt + 1'b1;
            out <= out_next;
        end
    end
    
    always @(*) begin
        case(MODE)
            0: out_next = (cnt == period);
            1: out_next = ($unsigned(cnt) >= $unsigned(period));
            2: out_next = ((cnt ^ period) & 8'h0F) == 8'h00;
            default: out_next = 1'b0;
        endcase
    end
endmodule