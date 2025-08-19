//SystemVerilog
//IEEE 1364-2005 Verilog
module crossbar_tdma #(
    parameter DW = 8,
    parameter N = 4
) (
    input wire clk,
    input wire [31:0] global_time,
    input wire [N-1:0][DW-1:0] din,
    output wire [N-1:0][DW-1:0] dout
);
    // Extract time slot from global time
    wire [1:0] time_slot;
    reg [31:0] global_time_buf; // 缓冲全局时间信号
    reg [1:0] time_slot_buf; // 缓冲time_slot信号
    wire [N-1:0][DW-1:0] din_buf; // 缓冲din信号

    // 注册全局时间以减少扇出负载
    always @(posedge clk) begin
        global_time_buf <= global_time;
    end
    
    // Instantiate submodules
    time_slot_extractor #(
        .TIME_WIDTH(32)
    ) time_slot_ext (
        .global_time(global_time_buf),
        .time_slot(time_slot)
    );
    
    // 注册time_slot以减少扇出负载
    always @(posedge clk) begin
        time_slot_buf <= time_slot;
    end
    
    // 为每个输入通道添加缓冲
    genvar g;
    generate
        for (g = 0; g < N; g = g + 1) begin : din_buffers
            din_buffer #(
                .DW(DW)
            ) din_buf_inst (
                .clk(clk),
                .din(din[g]),
                .dout(din_buf[g])
            );
        end
    endgenerate
    
    data_router #(
        .DW(DW),
        .N(N)
    ) router (
        .clk(clk),
        .time_slot(time_slot_buf),
        .din(din_buf),
        .dout(dout)
    );
    
endmodule

// Din缓冲模块
module din_buffer #(
    parameter DW = 8
) (
    input wire clk,
    input wire [DW-1:0] din,
    output reg [DW-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

module time_slot_extractor #(
    parameter TIME_WIDTH = 32
) (
    input wire [TIME_WIDTH-1:0] global_time,
    output wire [1:0] time_slot
);
    // Extract time slot bits from global time
    assign time_slot = global_time[27:26];
    
endmodule

module data_router #(
    parameter DW = 8,
    parameter N = 4
) (
    input wire clk,
    input wire [1:0] time_slot,
    input wire [N-1:0][DW-1:0] din,
    output wire [N-1:0][DW-1:0] dout
);
    // 使用寄存器进行扇出缓冲
    reg [1:0] time_slot_local;
    reg [DW-1:0] selected_din;
    reg [N-1:0][DW-1:0] dout_reg;
    
    // 本地缓存time_slot减少扇出
    always @(posedge clk) begin
        time_slot_local <= time_slot;
    end
    
    // 先选择输入数据
    always @(posedge clk) begin
        if (time_slot_local < N) begin
            selected_din <= din[time_slot_local];
        end else begin
            selected_din <= {DW{1'b0}};
        end
    end
    
    // 再将选中的数据分发到所有输出
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : dout_regs
            // 为每个输出通道使用独立寄存器，减少扇出负载
            always @(posedge clk) begin
                if (time_slot_local < N) begin
                    dout_reg[i] <= selected_din;
                end else begin
                    dout_reg[i] <= {DW{1'b0}};
                end
            end
            
            // 连接到输出
            assign dout[i] = dout_reg[i];
        end
    endgenerate
    
endmodule