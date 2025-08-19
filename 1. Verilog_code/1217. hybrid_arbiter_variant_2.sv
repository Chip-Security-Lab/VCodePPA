//SystemVerilog
module hybrid_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [1:0] rr_ptr;
    // Pre-compute the arbiter decision logic
    reg [WIDTH-1:0] next_grant;
    reg [1:0] next_rr_ptr;
    
    // Decision logic moved out of the register to optimize timing
    always @(*) begin
        next_grant = grant_o;
        next_rr_ptr = rr_ptr;
        
        if (req_i[3:2] == 2'b01 || req_i[3:2] == 2'b11) begin
            next_grant = 4'b0100;  // 优先级最高的请求
        end 
        else if (req_i[3:2] == 2'b10) begin
            next_grant = 4'b1000;  // 次优先级的请求
        end 
        else if (req_i[rr_ptr % 2]) begin
            next_grant = 1 << (rr_ptr % 2);  // 当前轮询指针位置有请求
            next_rr_ptr = (rr_ptr % 2) + 1;
        end 
        else if (req_i[(rr_ptr + 1) % 2]) begin
            next_grant = 1 << ((rr_ptr + 1) % 2);  // 下一个轮询位置有请求
            next_rr_ptr = ((rr_ptr + 1) % 2) + 1;
        end 
        else begin
            next_grant = 0;  // 无请求情况
        end
    end
    
    // Register the decision results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= 0;
            rr_ptr <= 0;
        end 
        else begin
            grant_o <= next_grant;
            rr_ptr <= next_rr_ptr;
        end
    end
endmodule