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
    
    // Pipeline stage registers
    reg [2:0] state_stage1, state_stage2, state_stage3;
    reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2;
    reg rd_en_stage1, wr_en_stage1;
    reg [7:0] data_in_stage1, data_in_stage2;
    reg [15:0] refresh_counter_stage1;
    reg [3:0] timer_stage1, timer_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Control signals
    reg [3:0] dram_cmd_stage1, dram_cmd_stage2;
    reg ready_stage1, ready_stage2;
    reg [ADDR_WIDTH-1:0] row_addr_stage1;
    reg [9:0] col_addr_stage1;
    
    // Pipeline stage 1 - Command decode and address preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            addr_stage1 <= 0;
            rd_en_stage1 <= 0;
            wr_en_stage1 <= 0;
            data_in_stage1 <= 0;
            refresh_counter_stage1 <= 0;
            timer_stage1 <= 0;
            valid_stage1 <= 0;
            dram_cmd_stage1 <= 4'b1111;
            ready_stage1 <= 1;
            row_addr_stage1 <= 0;
            col_addr_stage1 <= 0;
        end else begin
            state_stage1 <= next_state;
            addr_stage1 <= addr;
            rd_en_stage1 <= rd_en;
            wr_en_stage1 <= wr_en;
            data_in_stage1 <= data_in;
            refresh_counter_stage1 <= refresh_counter_stage1 + 1;
            valid_stage1 <= 1;
            
            case(state_stage1)
                IDLE: begin
                    ready_stage1 <= 1'b1;
                    dram_cmd_stage1 <= 4'b1111;
                    timer_stage1 <= 0;
                end
                ACTIVE: begin
                    ready_stage1 <= 1'b0;
                    dram_cmd_stage1 <= 4'b0011;
                    row_addr_stage1 <= addr_stage1[ADDR_WIDTH-1:10];
                    timer_stage1 <= tRFC;
                end
                READ: begin
                    ready_stage1 <= 1'b0;
                    dram_cmd_stage1 <= 4'b0101;
                    col_addr_stage1 <= addr_stage1[9:0];
                    timer_stage1 <= 4;
                end
                WRITE: begin
                    ready_stage1 <= 1'b0;
                    dram_cmd_stage1 <= 4'b0100;
                    col_addr_stage1 <= addr_stage1[9:0];
                    timer_stage1 <= 4;
                end
                PRECHARGE: begin
                    ready_stage1 <= 1'b0;
                    dram_cmd_stage1 <= 4'b0010;
                    timer_stage1 <= 2;
                end
                REFRESH: begin
                    ready_stage1 <= 1'b0;
                    dram_cmd_stage1 <= 4'b0001;
                    refresh_counter_stage1 <= 0;
                    timer_stage1 <= tRFC;
                end
                default: begin
                    dram_cmd_stage1 <= 4'b1111;
                    ready_stage1 <= 1'b1;
                end
            endcase
        end
    end

    // Pipeline stage 2 - Timer and data processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            addr_stage2 <= 0;
            data_in_stage2 <= 0;
            timer_stage2 <= 0;
            valid_stage2 <= 0;
            dram_cmd_stage2 <= 4'b1111;
            ready_stage2 <= 1;
        end else begin
            state_stage2 <= state_stage1;
            addr_stage2 <= addr_stage1;
            data_in_stage2 <= data_in_stage1;
            timer_stage2 <= timer_stage1 > 0 ? timer_stage1 - 1 : 0;
            valid_stage2 <= valid_stage1;
            dram_cmd_stage2 <= dram_cmd_stage1;
            ready_stage2 <= ready_stage1;
        end
    end

    // Pipeline stage 3 - Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            valid_stage3 <= 0;
            dram_cmd <= 4'b1111;
            ready <= 1;
            data_out <= 0;
        end else begin
            state_stage3 <= state_stage2;
            valid_stage3 <= valid_stage2;
            dram_cmd <= dram_cmd_stage2;
            ready <= ready_stage2;
            
            if (state_stage2 == READ && timer_stage2 == 0) begin
                data_out <= data_in_stage2;
            end
        end
    end

    // Next state logic
    reg [2:0] next_state;
    always @(*) begin
        next_state = state_stage1;
        case(state_stage1)
            IDLE: begin
                if (refresh_counter_stage1 >= REFRESH_CYCLES) begin
                    next_state = REFRESH;
                end else if (rd_en_stage1 || wr_en_stage1) begin
                    next_state = ACTIVE;
                end
            end
            ACTIVE: begin
                if (timer_stage1 == 0) begin
                    if (rd_en_stage1) next_state = READ;
                    else if (wr_en_stage1) next_state = WRITE;
                    else next_state = IDLE;
                end
            end
            READ: if (timer_stage1 == 0) next_state = PRECHARGE;
            WRITE: if (timer_stage1 == 0) next_state = PRECHARGE;
            PRECHARGE: if (timer_stage1 == 0) next_state = IDLE;
            REFRESH: if (timer_stage1 == 0) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule