//SystemVerilog
module GammaCorrection (
    input clk,
    input rst_n,
    
    // AXI-Stream Slave Interface
    input s_axis_tvalid,
    output s_axis_tready,
    input [7:0] s_axis_tdata,
    input s_axis_tlast,
    
    // AXI-Stream Master Interface
    output m_axis_tvalid,
    input m_axis_tready,
    output [7:0] m_axis_tdata,
    output m_axis_tlast
);

    // 预计算的Gamma=2.2查找表
    reg [7:0] gamma_lut [0:255];
    integer i;
    
    initial begin
        for(i=0; i<256; i=i+1) begin
            gamma_lut[i] = i > 128 ? (i-128)*2 : i/2;
        end
    end
    
    // 内部寄存器
    reg [7:0] pixel_in_reg;
    reg tlast_reg;
    reg valid_reg;
    
    // 状态机状态定义
    localparam IDLE = 1'b0;
    localparam PROCESS = 1'b1;
    reg state;
    
    // 状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid_reg <= 1'b0;
            tlast_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis_tvalid && s_axis_tready) begin
                        pixel_in_reg <= s_axis_tdata;
                        tlast_reg <= s_axis_tlast;
                        valid_reg <= 1'b1;
                        state <= PROCESS;
                    end
                end
                PROCESS: begin
                    if (m_axis_tready) begin
                        valid_reg <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // 输出信号赋值
    assign s_axis_tready = (state == IDLE);
    assign m_axis_tvalid = valid_reg;
    assign m_axis_tdata = gamma_lut[pixel_in_reg];
    assign m_axis_tlast = tlast_reg;
    
endmodule