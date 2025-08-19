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
    
    reg [15:0] refresh_counter;
    reg [ADDR_WIDTH-1:0] row_addr;
    reg [9:0] col_addr;
    reg [3:0] timer;
    
    wire timer_zero = ~|timer;
    wire need_refresh = &refresh_counter[15:12];
    wire [ADDR_WIDTH-1:0] row_addr_next = {addr[ADDR_WIDTH-1:10]};
    wire [9:0] col_addr_next = addr[9:0];
    wire [3:0] timer_next = timer_zero ? 4'b0 : timer - 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            refresh_counter <= 16'b0;
            dram_cmd <= 4'b1111;
            ready <= 1'b0;
            timer <= 4'b0;
            row_addr <= {ADDR_WIDTH{1'b0}};
            col_addr <= 10'b0;
            data_out <= 8'b0;
        end else begin
            current_state <= next_state;
            refresh_counter <= refresh_counter + 1'b1;
            
            case(current_state)
                IDLE: begin
                    ready <= 1'b1;
                    dram_cmd <= 4'b1111;
                end
                ACTIVE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0011;
                    row_addr <= row_addr_next;
                    timer <= timer_next;
                end
                READ: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0101;
                    col_addr <= col_addr_next;
                    if (timer_zero) data_out <= data_in;
                    timer <= timer_next;
                end
                WRITE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0100;
                    col_addr <= col_addr_next;
                    timer <= timer_next;
                end
                PRECHARGE: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0010;
                    timer <= timer_next;
                end
                REFRESH: begin
                    ready <= 1'b0;
                    dram_cmd <= 4'b0001;
                    refresh_counter <= 16'b0;
                    timer <= timer_next;
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
                if (need_refresh) next_state = REFRESH;
                else if (rd_en || wr_en) next_state = ACTIVE;
            end
            ACTIVE: begin
                if (timer_zero) begin
                    if (rd_en) next_state = READ;
                    else if (wr_en) next_state = WRITE;
                    else next_state = IDLE;
                end
            end
            READ: if (timer_zero) next_state = PRECHARGE;
            WRITE: if (timer_zero) next_state = PRECHARGE;
            PRECHARGE: if (timer_zero) next_state = IDLE;
            REFRESH: if (timer_zero) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule