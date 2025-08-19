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
    output reg [3:0] dram_cmd  // {RAS_n, CAS_n, WE_n}
);
    // 使用localparam代替typedef enum
    localparam IDLE = 3'b000, ACTIVE = 3'b001, READ = 3'b010, 
             WRITE = 3'b011, PRECHARGE = 3'b100, REFRESH = 3'b101;
    reg [2:0] current_state, next_state;
    
    reg [15:0] refresh_counter;
    reg [ADDR_WIDTH-1:0] row_addr;
    reg [9:0] col_addr; // 修改为适当的位宽
    reg [3:0] timer;

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
            current_state <= next_state;
            refresh_counter <= refresh_counter + 1;
            
            case(current_state)
                IDLE: begin
                    ready <= 1'b1;
                    dram_cmd <= 4'b1111; // 空闲状态
                end
                ACTIVE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0011; // ACTIVE命令
                    row_addr <= addr[ADDR_WIDTH-1:10];
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                READ: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0101; // READ命令
                    col_addr <= addr[9:0];
                    if (timer == 0) begin
                        data_out <= data_in; // 模拟读取数据
                    end
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                WRITE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0100; // WRITE命令
                    col_addr <= addr[9:0];
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                PRECHARGE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0010; // PRECHARGE命令
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                REFRESH: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0001; // REFRESH命令
                    refresh_counter <= 0; // 复位刷新计数器
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                default: begin
                    dram_cmd <= 4'b1111;
                    ready <= 1'b1;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: begin
                if (refresh_counter >= REFRESH_CYCLES) begin
                    next_state = REFRESH;
                end else if (rd_en || wr_en) begin
                    next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                if (timer == 0) begin
                    if (rd_en) next_state = READ;
                    else if (wr_en) next_state = WRITE;
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
endmodule