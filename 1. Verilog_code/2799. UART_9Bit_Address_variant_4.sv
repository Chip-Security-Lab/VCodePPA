//SystemVerilog
module UART_9Bit_Address #(
    parameter ADDRESS = 8'hFF
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        addr_mode_en,
    output reg         frame_match,
    input  wire        rx_start,
    input  wire        rx_bit9,
    input  wire        rx_done,
    input  wire [7:0]  rx_data,
    input  wire [8:0]  tx_data_9bit,
    output reg  [8:0]  rx_data_9bit
);

// 地址识别状态机
localparam ADDR_IDLE = 2'd0, ADDR_CHECK = 2'd1, DATA_PHASE = 2'd2;
reg [1:0] state;

// 地址匹配寄存器
reg [7:0] target_addr;
reg addr_flag;

// 输入信号前向寄存器
reg rx_start_reg;
reg rx_bit9_reg;
reg rx_done_reg;
reg [7:0] rx_data_reg;

// ----------- Pipeline registers for key path cut -----------
reg [1:0] state_pipeline;
reg frame_match_pipeline;
reg [7:0] target_addr_pipeline;
reg addr_flag_pipeline;
reg [8:0] rx_data_9bit_pipeline;

// Pipeline for rx_data_9bit building
reg [8:0] rx_data_9bit_build;

// Pipeline for address compare
reg addr_cmp_result;
reg addr_cmp_result_pipeline;
reg rx_done_reg_pipeline;
reg rx_bit9_reg_pipeline;
reg [7:0] rx_data_reg_pipeline;

// 输入信号打拍，前向寄存器重定时
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_start_reg  <= 1'b0;
        rx_bit9_reg   <= 1'b0;
        rx_done_reg   <= 1'b0;
        rx_data_reg   <= 8'd0;
    end else begin
        rx_start_reg  <= rx_start;
        rx_bit9_reg   <= rx_bit9;
        rx_done_reg   <= rx_done;
        rx_data_reg   <= rx_data;
    end
end

// -------- Pipeline Stage 1: Address Compare and Data Assembly --------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_cmp_result <= 1'b0;
        rx_data_9bit_build <= 9'd0;
        rx_done_reg_pipeline <= 1'b0;
        rx_bit9_reg_pipeline <= 1'b0;
        rx_data_reg_pipeline <= 8'd0;
    end else begin
        addr_cmp_result <= (rx_data_reg == ADDRESS);
        rx_data_9bit_build <= {rx_bit9_reg, rx_data_reg};
        rx_done_reg_pipeline <= rx_done_reg;
        rx_bit9_reg_pipeline <= rx_bit9_reg;
        rx_data_reg_pipeline <= rx_data_reg;
    end
end

// -------- Pipeline Stage 2: Address Compare Result & Main FSM --------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_cmp_result_pipeline <= 1'b0;
    end else begin
        addr_cmp_result_pipeline <= addr_cmp_result;
    end
end

// -------- Pipeline Stage 3: FSM and Output Registers --------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_pipeline <= ADDR_IDLE;
        frame_match_pipeline <= 1'b0;
        target_addr_pipeline <= ADDRESS;
        rx_data_9bit_pipeline <= 9'd0;
        addr_flag_pipeline <= 1'b0;
    end else if (addr_mode_en) begin
        case (state_pipeline)
            ADDR_IDLE: begin
                if (rx_start_reg && rx_bit9_reg) begin
                    state_pipeline <= ADDR_CHECK;
                    frame_match_pipeline <= 1'b0;
                end else begin
                    frame_match_pipeline <= 1'b0;
                end
            end
            ADDR_CHECK: begin
                if (rx_done_reg_pipeline) begin
                    if (addr_cmp_result_pipeline) begin
                        frame_match_pipeline <= 1'b1;
                        state_pipeline <= DATA_PHASE;
                    end else begin
                        frame_match_pipeline <= 1'b0;
                        state_pipeline <= ADDR_IDLE;
                    end
                end
            end
            DATA_PHASE: begin
                if (rx_done_reg_pipeline) begin
                    rx_data_9bit_pipeline <= {rx_bit9_reg_pipeline, rx_data_reg_pipeline};
                    if (!rx_bit9_reg_pipeline) begin
                        state_pipeline <= DATA_PHASE;
                    end else begin
                        state_pipeline <= ADDR_CHECK;
                    end
                end
            end
            default: begin
                state_pipeline <= ADDR_IDLE;
                frame_match_pipeline <= 1'b0;
            end
        endcase
    end
end

// -------- Output Register Stage --------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= ADDR_IDLE;
        frame_match <= 1'b0;
        target_addr <= ADDRESS;
        rx_data_9bit <= 9'd0;
        addr_flag <= 1'b0;
    end else begin
        state <= state_pipeline;
        frame_match <= frame_match_pipeline;
        target_addr <= target_addr_pipeline;
        rx_data_9bit <= rx_data_9bit_pipeline;
        addr_flag <= addr_flag_pipeline;
    end
end

// 数据位扩展逻辑
wire [8:0] tx_packet;
assign tx_packet = {addr_flag, tx_data_9bit[7:0]};

endmodule