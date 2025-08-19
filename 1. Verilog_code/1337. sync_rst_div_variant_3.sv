//SystemVerilog
module sync_rst_div #(parameter DIV=8) (
    input clk, async_rst,
    output reg clk_out
);
    reg [2:0] sync_rst_reg;
    reg [3:0] cnt;
    
    // Asynchronous reset synchronizer
    always @(posedge clk, posedge async_rst) begin
        if(async_rst)
            sync_rst_reg <= 3'b111;
        else
            sync_rst_reg <= {sync_rst_reg[1:0], 1'b0};
    end
    
    // Divider counter logic with case statement
    reg [1:0] state;
    always @(*) begin
        if(sync_rst_reg[2])
            state = 2'b00;  // Reset state
        else if(cnt == DIV/2-1)
            state = 2'b01;  // Counter reached half division
        else
            state = 2'b10;  // Normal counting
    end
    
    always @(posedge clk) begin
        case(state)
            2'b00: begin  // Reset state
                cnt <= 0;
                clk_out <= 0;
            end
            
            2'b01: begin  // Counter reached half division
                cnt <= 0;
                clk_out <= ~clk_out;
            end
            
            2'b10: begin  // Normal counting
                cnt <= cnt + 1;
            end
            
            default: begin  // Catch-all for better synthesis
                cnt <= cnt;
                clk_out <= clk_out;
            end
        endcase
    end
endmodule