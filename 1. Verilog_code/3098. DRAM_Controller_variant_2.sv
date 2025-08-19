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
    
    reg [2:0] current_state, next_state;
    reg [2:0] next_state_buf;
    reg [15:0] refresh_counter;
    reg [ADDR_WIDTH-1:0] row_addr;
    reg [ADDR_WIDTH-1:0] addr_buf;
    reg [9:0] col_addr;
    reg [3:0] timer;
    reg [3:0] timer_buf;
    reg IDLE_buf;
    wire refresh_needed;
    wire timer_expired;
    wire operation_pending;

    assign refresh_needed = (refresh_counter >= REFRESH_CYCLES);
    assign timer_expired = (timer_buf == 0);
    assign operation_pending = rd_en || wr_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            next_state_buf <= IDLE;
            refresh_counter <= 0;
            dram_cmd <= 4'b1111;
            ready <= 0;
            timer <= 0;
            timer_buf <= 0;
            row_addr <= 0;
            col_addr <= 0;
            data_out <= 0;
            addr_buf <= 0;
            IDLE_buf <= 1'b1;
        end else begin
            current_state <= next_state_buf;
            next_state_buf <= next_state;
            refresh_counter <= refresh_counter + 1;
            addr_buf <= addr;
            IDLE_buf <= (current_state == IDLE);
            
            case(current_state)
                IDLE: begin
                    ready <= 1'b1;
                    dram_cmd <= 4'b1111;
                end
                ACTIVE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0011;
                    row_addr <= addr_buf[ADDR_WIDTH-1:10];
                    timer <= timer > 0 ? timer - 1 : 0;
                    timer_buf <= timer;
                end
                READ: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0101;
                    col_addr <= addr_buf[9:0];
                    if (timer_expired) begin
                        data_out <= data_in;
                    end
                    timer <= timer > 0 ? timer - 1 : 0;
                    timer_buf <= timer;
                end
                WRITE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0100;
                    col_addr <= addr_buf[9:0];
                    timer <= timer > 0 ? timer - 1 : 0;
                    timer_buf <= timer;
                end
                PRECHARGE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0010;
                    timer <= timer > 0 ? timer - 1 : 0;
                    timer_buf <= timer;
                end
                REFRESH: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0001;
                    refresh_counter <= 0;
                    timer <= timer > 0 ? timer - 1 : 0;
                    timer_buf <= timer;
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
                if (refresh_needed) begin
                    next_state = REFRESH;
                end else if (operation_pending) begin
                    next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                if (timer_expired) begin
                    next_state = rd_en ? READ : (wr_en ? WRITE : IDLE);
                end
            end
            READ: if (timer_expired) next_state = PRECHARGE;
            WRITE: if (timer_expired) next_state = PRECHARGE;
            PRECHARGE: if (timer_expired) next_state = IDLE;
            REFRESH: if (timer_expired) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule