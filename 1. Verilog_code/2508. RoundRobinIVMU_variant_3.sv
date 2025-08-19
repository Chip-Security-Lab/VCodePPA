//SystemVerilog
module RoundRobinIVMU (
    input clk, rst,
    input [7:0] irq,
    input ack,
    output reg [31:0] vector,
    output reg valid
);
    reg [2:0] last_served;
    reg [31:0] vector_table [0:7];
    reg [7:0] pending;
    integer i;
    
    // 初始化向量表
    initial begin
        vector_table[0] = 32'h6000_0000;
        vector_table[1] = 32'h6000_0020;
        vector_table[2] = 32'h6000_0040;
        vector_table[3] = 32'h6000_0060;
        vector_table[4] = 32'h6000_0080;
        vector_table[5] = 32'h6000_00A0;
        vector_table[6] = 32'h6000_00C0;
        vector_table[7] = 32'h6000_00E0;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            last_served <= 3'b0;
            pending <= 8'b0;
            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            pending <= pending | irq;
            
            if (ack) valid <= 1'b0;
            
            if (!valid && |pending) begin
                valid <= 1'b1;
                // 移除嵌套循环，使用组合逻辑查找下一个中断
                if (pending[(last_served + 1) % 8]) begin
                    vector <= vector_table[(last_served + 1) % 8];
                    pending[(last_served + 1) % 8] <= 1'b0;
                    last_served <= (last_served + 1) % 8;
                end else if (pending[(last_served + 2) % 8]) begin
                    vector <= vector_table[(last_served + 2) % 8];
                    pending[(last_served + 2) % 8] <= 1'b0;
                    last_served <= (last_served + 2) % 8;
                end else if (pending[(last_served + 3) % 8]) begin
                    vector <= vector_table[(last_served + 3) % 8];
                    pending[(last_served + 3) % 8] <= 1'b0;
                    last_served <= (last_served + 3) % 8;
                end else if (pending[(last_served + 4) % 8]) begin
                    vector <= vector_table[(last_served + 4) % 8];
                    pending[(last_served + 4) % 8] <= 1'b0;
                    last_served <= (last_served + 4) % 8;
                end else if (pending[(last_served + 5) % 8]) begin
                    vector <= vector_table[(last_served + 5) % 8];
                    pending[(last_served + 5) % 8] <= 1'b0;
                    last_served <= (last_served + 5) % 8;
                end else if (pending[(last_served + 6) % 8]) begin
                    vector <= vector_table[(last_served + 6) % 8];
                    pending[(last_served + 6) % 8] <= 1'b0;
                    last_served <= (last_served + 6) % 8;
                end else if (pending[(last_served + 7) % 8]) begin
                    vector <= vector_table[(last_served + 7) % 8];
                    pending[(last_served + 7) % 8] <= 1'b0;
                    last_served <= (last_served + 7) % 8;
                end else if (pending[last_served]) begin
                    vector <= vector_table[last_served];
                    pending[last_served] <= 1'b0;
                end
            end
        end
    end
endmodule