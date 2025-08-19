//SystemVerilog
module DRAM_Controller #(
    parameter ADDR_WIDTH = 16,
    parameter REFRESH_CYCLES = 4096,
    parameter tRFC = 8
)(
    input clk, rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input rd_en, wr_en,
    output reg [7:0] data_out,
    input [7:0] data_in,
    output reg ready,
    output reg [3:0] dram_cmd
);

    localparam IDLE = 3'b000, ACTIVE = 3'b001, READ = 3'b010, 
             WRITE = 3'b011, PRECHARGE = 3'b100, REFRESH = 3'b101;
    
    // 状态寄存器 - 增加流水线级数
    reg [2:0] current_state, next_state;
    reg [2:0] next_state_buf;
    reg [2:0] next_state_buf2;
    
    // 地址缓冲寄存器 - 增加流水线级数
    reg [ADDR_WIDTH-1:0] addr_buf;
    reg [ADDR_WIDTH-1:0] addr_buf2;
    reg [ADDR_WIDTH-1:0] row_addr;
    reg [ADDR_WIDTH-1:0] row_addr_buf;
    reg [9:0] col_addr;
    reg [9:0] col_addr_buf;
    
    // 定时器缓冲寄存器 - 增加流水线级数
    reg [3:0] timer;
    reg [3:0] timer_buf;
    reg [3:0] timer_buf2;
    
    // 刷新计数器缓冲寄存器 - 增加流水线级数
    reg [15:0] refresh_counter;
    reg [15:0] refresh_counter_buf;
    reg [15:0] refresh_counter_buf2;
    
    // 控制信号缓冲寄存器 - 增加流水线级数
    reg rd_en_buf, wr_en_buf;
    reg rd_en_buf2, wr_en_buf2;
    reg [3:0] dram_cmd_buf;
    reg [3:0] dram_cmd_buf2;
    reg ready_buf;
    reg ready_buf2;
    reg [7:0] data_out_buf;
    reg [7:0] data_out_buf2;

    // 输入信号缓冲 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_buf <= 0;
            rd_en_buf <= 0;
            wr_en_buf <= 0;
        end else begin
            addr_buf <= addr;
            rd_en_buf <= rd_en;
            wr_en_buf <= wr_en;
        end
    end

    // 输入信号缓冲 - 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_buf2 <= 0;
            rd_en_buf2 <= 0;
            wr_en_buf2 <= 0;
        end else begin
            addr_buf2 <= addr_buf;
            rd_en_buf2 <= rd_en_buf;
            wr_en_buf2 <= wr_en_buf;
        end
    end

    // 状态机主逻辑 - 增加流水线级数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            refresh_counter <= 0;
            dram_cmd <= 4'b1111;
            ready <= 0;
            timer <= 0;
            row_addr <= 0;
            col_addr <= 0;
            data_out <= 0;
        end else begin
            current_state <= next_state_buf2;
            refresh_counter <= refresh_counter_buf2;
            dram_cmd <= dram_cmd_buf2;
            ready <= ready_buf2;
            timer <= timer_buf2;
            data_out <= data_out_buf2;
            
            case(current_state)
                IDLE: begin
                    ready_buf <= 1'b1;
                    dram_cmd_buf <= 4'b1111;
                end
                ACTIVE: begin
                    ready_buf <= 1'b0;
                    dram_cmd_buf <= 4'b0011;
                    row_addr <= addr_buf2[ADDR_WIDTH-1:10];
                    timer_buf <= timer > 0 ? timer - 1 : 0;
                end
                READ: begin
                    ready_buf <= 1'b0;
                    dram_cmd_buf <= 4'b0101;
                    col_addr <= addr_buf2[9:0];
                    if (timer == 0) begin
                        data_out_buf <= data_in;
                    end
                    timer_buf <= timer > 0 ? timer - 1 : 0;
                end
                WRITE: begin
                    ready_buf <= 1'b0;
                    dram_cmd_buf <= 4'b0100;
                    col_addr <= addr_buf2[9:0];
                    timer_buf <= timer > 0 ? timer - 1 : 0;
                end
                PRECHARGE: begin
                    ready_buf <= 1'b0;
                    dram_cmd_buf <= 4'b0010;
                    timer_buf <= timer > 0 ? timer - 1 : 0;
                end
                REFRESH: begin
                    ready_buf <= 1'b0;
                    dram_cmd_buf <= 4'b0001;
                    refresh_counter_buf <= 0;
                    timer_buf <= timer > 0 ? timer - 1 : 0;
                end
                default: begin
                    dram_cmd_buf <= 4'b1111;
                    ready_buf <= 1'b1;
                end
            endcase
        end
    end

    // 状态转换逻辑 - 增加流水线级数
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: begin
                if (refresh_counter >= REFRESH_CYCLES) begin
                    next_state = REFRESH;
                end else if (rd_en_buf2 || wr_en_buf2) begin
                    next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                if (timer == 0) begin
                    if (rd_en_buf2) next_state = READ;
                    else if (wr_en_buf2) next_state = WRITE;
                    else next_state = IDLE;
                end
            end
            READ: if (timer == 0) next_state = PRECHARGE;
            WRITE: if (timer == 0) next_state = PRECHARGE;
            PRECHARGE: if (timer == 0) next_state = IDLE;
            REFRESH: if (timer == 0) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 状态缓冲 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_buf <= IDLE;
        end else begin
            next_state_buf <= next_state;
        end
    end

    // 状态缓冲 - 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_buf2 <= IDLE;
        end else begin
            next_state_buf2 <= next_state_buf;
        end
    end

    // 控制信号缓冲 - 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dram_cmd_buf2 <= 4'b1111;
            ready_buf2 <= 0;
            data_out_buf2 <= 0;
            timer_buf2 <= 0;
            refresh_counter_buf2 <= 0;
            row_addr_buf <= 0;
            col_addr_buf <= 0;
        end else begin
            dram_cmd_buf2 <= dram_cmd_buf;
            ready_buf2 <= ready_buf;
            data_out_buf2 <= data_out_buf;
            timer_buf2 <= timer_buf;
            refresh_counter_buf2 <= refresh_counter_buf;
            row_addr_buf <= row_addr;
            col_addr_buf <= col_addr;
        end
    end
endmodule