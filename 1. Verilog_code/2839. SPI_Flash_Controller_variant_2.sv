//SystemVerilog
module SPI_Flash_Controller #(
    parameter ADDR_WIDTH = 24
)(
    input clk,
    input rst,
    input start,
    input [7:0] cmd,
    input [ADDR_WIDTH-1:0] addr,
    input [7:0] wr_data,
    output [7:0] rd_data,
    output reg ready,
    output sclk,
    output cs_n,
    output mosi,
    input miso
);

    // 寄存器信号
    reg [3:0] state_reg, state_next;
    reg [ADDR_WIDTH-1:0] addr_reg, addr_next;
    reg [7:0] cmd_reg, cmd_next;
    reg [7:0] shift_reg, shift_next;
    reg [2:0] phase_cnt_reg, phase_cnt_next;
    reg [7:0] byte_cnt_reg, byte_cnt_next;
    reg [7:0] data_len_reg, data_len_next;
    reg sclk_reg, sclk_next;
    reg cs_n_reg, cs_n_next;
    reg ready_next;

    // 二进制编码状态定义 (12个状态需4位)
    localparam [3:0]
        S_IDLE        = 4'd0,
        S_CMD         = 4'd1,
        S_ADDR_PHASE  = 4'd2,
        S_DATA_PHASE  = 4'd3,
        S_DONE        = 4'd4,
        S_STATE5      = 4'd5,
        S_STATE6      = 4'd6,
        S_STATE7      = 4'd7,
        S_STATE8      = 4'd8,
        S_STATE9      = 4'd9,
        S_STATE10     = 4'd10,
        S_STATE11     = 4'd11;

    // 组合逻辑输出
    assign sclk = sclk_reg;
    assign cs_n = cs_n_reg;
    assign mosi = shift_reg[7];
    assign rd_data = shift_reg;

    // 组合逻辑：状态转移和输出信号
    always @(*) begin
        // 默认保持
        state_next      = state_reg;
        addr_next       = addr_reg;
        cmd_next        = cmd_reg;
        shift_next      = shift_reg;
        phase_cnt_next  = phase_cnt_reg;
        byte_cnt_next   = byte_cnt_reg;
        data_len_next   = data_len_reg;
        sclk_next       = sclk_reg;
        cs_n_next       = cs_n_reg;
        ready_next      = ready;

        case (state_reg)
            S_IDLE: begin
                sclk_next  = 1'b0;
                cs_n_next  = 1'b1;
                ready_next = 1'b1;

                if (start) begin
                    cmd_next       = cmd;
                    addr_next      = addr;
                    state_next     = S_CMD;
                    phase_cnt_next = 3'd0;
                    byte_cnt_next  = 8'd0;
                    shift_next     = cmd;
                    data_len_next  = (cmd == 8'h03) ? 8 : 
                                     (cmd == 8'h02) ? 8 :
                                     (cmd == 8'h06) ? 0 : 0;
                end
            end

            S_CMD: begin
                sclk_next  = ~sclk_reg;
                cs_n_next  = 1'b0;
                ready_next = 1'b0;

                if ((phase_cnt_reg == 3'd7) && (cmd_reg[7])) begin
                    state_next     = S_ADDR_PHASE;
                    phase_cnt_next = 3'd0;
                    shift_next     = addr_reg[ADDR_WIDTH-1 -: 8];
                end else if ((phase_cnt_reg == 3'd7) && (!cmd_reg[7])) begin
                    state_next     = S_DATA_PHASE;
                    phase_cnt_next = 3'd0;
                    shift_next     = addr_reg[ADDR_WIDTH-1 -: 8];
                end else if ((phase_cnt_reg != 3'd7) && (!sclk_reg)) begin
                    phase_cnt_next = phase_cnt_reg + 1'b1;
                    shift_next     = {shift_reg[6:0], miso};
                end else if ((phase_cnt_reg != 3'd7) && (sclk_reg)) begin
                    phase_cnt_next = phase_cnt_reg + 1'b1;
                end
            end

            S_ADDR_PHASE: begin
                sclk_next  = ~sclk_reg;
                cs_n_next  = 1'b0;
                ready_next = 1'b0;

                if ((phase_cnt_reg == ADDR_WIDTH-1)) begin
                    state_next     = S_DATA_PHASE;
                    phase_cnt_next = 3'd0;
                    shift_next     = wr_data;
                end else if ((phase_cnt_reg != ADDR_WIDTH-1) && (!sclk_reg)) begin
                    phase_cnt_next = phase_cnt_reg + 1'b1;
                    shift_next     = {shift_reg[6:0], miso};
                end else if ((phase_cnt_reg != ADDR_WIDTH-1) && (sclk_reg)) begin
                    phase_cnt_next = phase_cnt_reg + 1'b1;
                end
            end

            S_DATA_PHASE: begin
                sclk_next  = ~sclk_reg;
                cs_n_next  = 1'b0;
                ready_next = 1'b0;

                if (byte_cnt_reg == data_len_reg) begin
                    state_next = S_DONE;
                end else if ((byte_cnt_reg != data_len_reg) && (phase_cnt_reg == 3'd7)) begin
                    byte_cnt_next  = byte_cnt_reg + 1'b1;
                    phase_cnt_next = 3'd0;
                    shift_next     = wr_data;
                end else if ((byte_cnt_reg != data_len_reg) && (phase_cnt_reg != 3'd7) && (!sclk_reg)) begin
                    phase_cnt_next = phase_cnt_reg + 1'b1;
                    shift_next     = {shift_reg[6:0], miso};
                end else if ((byte_cnt_reg != data_len_reg) && (phase_cnt_reg != 3'd7) && (sclk_reg)) begin
                    phase_cnt_next = phase_cnt_reg + 1'b1;
                end
            end

            S_DONE: begin
                sclk_next  = 1'b0;
                cs_n_next  = 1'b1;
                ready_next = 1'b1;
                state_next = S_IDLE;
            end

            S_STATE5,
            S_STATE6,
            S_STATE7,
            S_STATE8,
            S_STATE9,
            S_STATE10,
            S_STATE11: begin
                // 保持空闲，未使用状态
                state_next = S_IDLE;
                sclk_next  = 1'b0;
                cs_n_next  = 1'b1;
                ready_next = 1'b1;
            end

            default: begin
                state_next = S_IDLE;
                sclk_next  = 1'b0;
                cs_n_next  = 1'b1;
                ready_next = 1'b1;
            end
        endcase
    end

    // 时序逻辑：寄存器赋值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg      <= S_IDLE;
            addr_reg       <= {ADDR_WIDTH{1'b0}};
            cmd_reg        <= 8'b0;
            shift_reg      <= 8'b0;
            phase_cnt_reg  <= 3'b0;
            byte_cnt_reg   <= 8'b0;
            data_len_reg   <= 8'b0;
            sclk_reg       <= 1'b0;
            cs_n_reg       <= 1'b1;
            ready          <= 1'b1;
        end else begin
            state_reg      <= state_next;
            addr_reg       <= addr_next;
            cmd_reg        <= cmd_next;
            shift_reg      <= shift_next;
            phase_cnt_reg  <= phase_cnt_next;
            byte_cnt_reg   <= byte_cnt_next;
            data_len_reg   <= data_len_next;
            sclk_reg       <= sclk_next;
            cs_n_reg       <= cs_n_next;
            ready          <= ready_next;
        end
    end

endmodule