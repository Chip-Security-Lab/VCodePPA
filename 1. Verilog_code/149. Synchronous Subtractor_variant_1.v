// 顶层模块
module subtractor_axi_stream (
    input wire clk,                    // 时钟信号
    input wire rst_n,                  // 低电平有效复位信号
    
    // AXI-Stream 输入接口
    input wire [7:0] s_axis_tdata,     // 输入数据
    input wire s_axis_tvalid,          // 输入数据有效
    output wire s_axis_tready,         // 输入就绪
    
    // AXI-Stream 输出接口  
    output wire [7:0] m_axis_tdata,    // 输出数据
    output wire m_axis_tvalid,         // 输出数据有效
    input wire m_axis_tready,          // 输出就绪
    output wire m_axis_tlast           // 最后一个数据标志
);

    // 内部信号
    wire [7:0] a_reg;
    wire [7:0] b_reg;
    wire [7:0] result;
    wire state;
    wire calc_start;
    wire calc_done;
    wire output_valid;
    wire output_ready;

    // 实例化数据寄存器模块
    data_registers data_regs (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .state(state),
        .a_reg(a_reg),
        .b_reg(b_reg),
        .calc_start(calc_start)
    );

    // 实例化计算模块
    calculation_unit calc_unit (
        .clk(clk),
        .rst_n(rst_n),
        .a_reg(a_reg),
        .b_reg(b_reg),
        .calc_start(calc_start),
        .calc_done(calc_done),
        .result(result)
    );

    // 实例化输出控制模块
    output_controller out_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .result(result),
        .calc_done(calc_done),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .output_valid(output_valid),
        .output_ready(output_ready)
    );

    // 实例化状态机模块
    state_machine state_mach (
        .clk(clk),
        .rst_n(rst_n),
        .calc_start(calc_start),
        .calc_done(calc_done),
        .output_valid(output_valid),
        .output_ready(output_ready),
        .state(state)
    );

endmodule

// 数据寄存器模块
module data_registers (
    input wire clk,
    input wire rst_n,
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire state,
    output reg [7:0] a_reg,
    output reg [7:0] b_reg,
    output reg calc_start
);

    // 状态定义
    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready <= 1'b0;
            a_reg <= 8'h0;
            b_reg <= 8'h0;
            calc_start <= 1'b0;
        end else begin
            calc_start <= 1'b0;
            
            if (state == IDLE) begin
                s_axis_tready <= 1'b1;
                
                if (s_axis_tvalid && s_axis_tready) begin
                    a_reg <= s_axis_tdata;
                    s_axis_tready <= 1'b0;
                end
            end else if (state == CALC) begin
                s_axis_tready <= 1'b1;
                
                if (s_axis_tvalid && s_axis_tready) begin
                    b_reg <= s_axis_tdata;
                    calc_start <= 1'b1;
                    s_axis_tready <= 1'b0;
                end
            end
        end
    end

endmodule

// 计算模块
module calculation_unit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a_reg,
    input wire [7:0] b_reg,
    input wire calc_start,
    output reg calc_done,
    output reg [7:0] result
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'h0;
            calc_done <= 1'b0;
        end else begin
            calc_done <= 1'b0;
            
            if (calc_start) begin
                result <= a_reg - b_reg;
                calc_done <= 1'b1;
            end
        end
    end

endmodule

// 输出控制模块
module output_controller (
    input wire clk,
    input wire rst_n,
    input wire [7:0] result,
    input wire calc_done,
    input wire m_axis_tready,
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tvalid,
    output reg m_axis_tlast,
    output reg output_valid,
    input wire output_ready
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tdata <= 8'h0;
            output_valid <= 1'b0;
        end else begin
            if (calc_done) begin
                m_axis_tdata <= result;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;
                output_valid <= 1'b1;
            end
            
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                output_valid <= 1'b0;
            end
        end
    end

endmodule

// 状态机模块
module state_machine (
    input wire clk,
    input wire rst_n,
    input wire calc_start,
    input wire calc_done,
    input wire output_valid,
    input wire output_ready,
    output reg state
);

    // 状态定义
    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (calc_start) begin
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    if (calc_done) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule