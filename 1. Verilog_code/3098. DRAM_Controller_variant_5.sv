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
    output reg [3:0] dram_cmd  // {RAS_n, CAS_n, WE_n}
);
    // 使用二进制编码
    localparam IDLE = 4'b0000, ACTIVE = 4'b0001, READ = 4'b0010, 
             WRITE = 4'b0011, PRECHARGE = 4'b0100, REFRESH = 4'b0101;
    reg [3:0] current_state, next_state;
    
    reg [15:0] refresh_counter;
    reg [ADDR_WIDTH-1:0] row_addr;
    reg [9:0] col_addr;
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
                    dram_cmd <= 4'b1111;
                end
                ACTIVE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0011;
                    row_addr <= addr[ADDR_WIDTH-1:10];
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                READ: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0101;
                    col_addr <= addr[9:0];
                    if (timer == 0) begin
                        data_out <= data_in;
                    end
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                WRITE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0100;
                    col_addr <= addr[9:0];
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                PRECHARGE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0010;
                    timer <= timer > 0 ? timer - 1 : 0;
                end
                REFRESH: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0001;
                    refresh_counter <= 0;
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