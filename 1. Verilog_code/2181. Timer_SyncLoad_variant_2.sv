//SystemVerilog
module Timer_SyncLoad #(parameter WIDTH=8) (
    input clk, rst_n, enable,
    input [WIDTH-1:0] preset,
    output reg timeout
);
    reg [WIDTH-1:0] cnt, next_cnt;
    reg next_timeout;
    reg count_done_reg;
    wire count_done;
    
    // Move comparison logic before register
    assign count_done = (cnt == preset);
    
    // Compute next state combinationally
    always @(*) begin
        next_cnt = cnt;
        next_timeout = timeout;
        
        if (enable) begin
            next_cnt = count_done ? {WIDTH{1'b0}} : cnt + 1'b1;
            next_timeout = count_done_reg;
        end
    end
    
    // Register updates - separated reset and data path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= {WIDTH{1'b0}};
            count_done_reg <= 1'b0;
            timeout <= 1'b0;
        end else begin
            cnt <= next_cnt;
            count_done_reg <= count_done;
            timeout <= next_timeout;
        end
    end
endmodule