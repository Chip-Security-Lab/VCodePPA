//SystemVerilog
// 顶层模块
module rom_pipelined #(parameter STAGES=2)(
    input clk,
    input [9:0] addr_in,
    output [7:0] data_out
);
    // 内部连接信号
    wire [9:0] addr_piped;
    wire [7:0] mem_data;
    
    // 地址管线实例
    address_pipeline #(
        .STAGES(STAGES)
    ) addr_pipe_inst (
        .clk(clk),
        .addr_in(addr_in),
        .addr_out(addr_piped)
    );
    
    // ROM存储器实例
    rom_memory rom_inst (
        .clk(clk),
        .addr(addr_piped),
        .data_out(mem_data)
    );
    
    // 数据管线实例
    data_pipeline #(
        .STAGES(STAGES-1)  // 减1是因为ROM已经消耗了一个周期
    ) data_pipe_inst (
        .clk(clk),
        .data_in(mem_data),
        .data_out(data_out)
    );
endmodule

// 地址管线子模块
module address_pipeline #(parameter STAGES=2)(
    input clk,
    input [9:0] addr_in,
    output [9:0] addr_out
);
    reg [9:0] pipe_addr [0:STAGES-1];
    integer i;
    
    always @(posedge clk) begin
        pipe_addr[0] <= addr_in;
        for(i = 1; i < STAGES; i = i + 1)
            pipe_addr[i] <= pipe_addr[i-1];
    end
    
    assign addr_out = pipe_addr[STAGES-1];
endmodule

// ROM存储器子模块
module rom_memory (
    input clk,
    input [9:0] addr,
    output reg [7:0] data_out
);
    reg [7:0] mem [0:1023];
    
    integer i;
    
    // 初始化存储器
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = i & 8'hFF; // 测试用简单模式
    end
    
    always @(posedge clk) begin
        data_out <= mem[addr];
    end
endmodule

// 数据管线子模块
module data_pipeline #(parameter STAGES=1)(
    input clk,
    input [7:0] data_in,
    output [7:0] data_out
);
    // 如果STAGES为0，直接连接输入和输出
    generate
        if (STAGES == 0) begin
            assign data_out = data_in;
        end else begin
            // 否则创建管线寄存器
            reg [7:0] pipe_data [0:STAGES-1];
            integer i;
            
            always @(posedge clk) begin
                pipe_data[0] <= data_in;
                for(i = 1; i < STAGES; i = i + 1)
                    pipe_data[i] <= pipe_data[i-1];
            end
            
            assign data_out = pipe_data[STAGES-1];
        end
    endgenerate
endmodule