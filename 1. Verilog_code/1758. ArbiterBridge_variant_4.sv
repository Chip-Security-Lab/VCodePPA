//SystemVerilog
module ArbiterBridge #(
    parameter MASTERS = 4
)(
    input clk, rst_n,
    input [MASTERS-1:0] req,
    output reg [MASTERS-1:0] grant
);
    reg [1:0] priority_ptr;
    reg [$clog2(MASTERS)-1:0] next_priority;
    wire [MASTERS-1:0] shifted_req;
    wire req_valid;
    
    // 创建轮转的请求信号
    generate
        genvar g;
        for (g = 0; g < MASTERS; g = g + 1) begin : gen_shift
            assign shifted_req[g] = req[(priority_ptr+g)%MASTERS];
        end
    endgenerate
    
    // 检查是否有任何请求
    assign req_valid = |req;
    
    // 扁平化的仲裁逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 0;
            priority_ptr <= 0;
            next_priority <= 0;
        end else begin
            if (shifted_req[0]) begin
                grant <= 1 << ((priority_ptr)%MASTERS);
                next_priority <= (priority_ptr+1)%MASTERS;
            end else if (shifted_req[1]) begin
                grant <= 1 << ((priority_ptr+1)%MASTERS);
                next_priority <= (priority_ptr+2)%MASTERS;
            end else if (shifted_req[2]) begin
                grant <= 1 << ((priority_ptr+2)%MASTERS);
                next_priority <= (priority_ptr+3)%MASTERS;
            end else if (shifted_req[3]) begin
                grant <= 1 << ((priority_ptr+3)%MASTERS);
                next_priority <= (priority_ptr+4)%MASTERS;
            end else begin
                grant <= 0;
                next_priority <= priority_ptr;
            end
            
            priority_ptr <= next_priority;
        end
    end
endmodule