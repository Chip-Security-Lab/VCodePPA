//SystemVerilog
module memory_access_controller(
    input wire clk,
    input wire rst_n,
    input wire request,
    input wire rw,
    input wire [7:0] addr,
    input wire [15:0] write_data,
    input wire mem_ready,
    output reg [15:0] read_data,
    output reg [7:0] mem_addr,
    output reg [15:0] mem_data,
    output reg mem_write_en,
    output reg busy,
    output reg done
);

    parameter [1:0] IDLE = 2'b00, READ_STATE = 2'b01, 
                    WRITE_STATE = 2'b10, WAIT = 2'b11;
    
    // Pipeline stage 1 registers
    reg [1:0] state_stage1, next_state_stage1;
    reg busy_stage1;
    reg rw_stage1;
    reg [7:0] addr_stage1;
    reg [15:0] write_data_stage1;
    reg request_stage1;
    
    // Pipeline stage 2 registers
    reg [1:0] state_stage2;
    reg busy_stage2;
    reg rw_stage2;
    reg [7:0] addr_stage2;
    reg [15:0] write_data_stage2;
    reg mem_write_en_stage2;
    
    // Pipeline stage 3 registers
    reg [1:0] state_stage3;
    reg busy_stage3;
    reg rw_stage3;
    reg [15:0] read_data_stage3;
    reg done_stage3;
    
    // Stage 1: Request and address capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            busy_stage1 <= 0;
            rw_stage1 <= 0;
            addr_stage1 <= 0;
            write_data_stage1 <= 0;
            request_stage1 <= 0;
        end else begin
            state_stage1 <= next_state_stage1;
            busy_stage1 <= request;
            rw_stage1 <= rw;
            addr_stage1 <= addr;
            write_data_stage1 <= write_data;
            request_stage1 <= request;
        end
    end
    
    // Stage 2: Memory operation preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            busy_stage2 <= 0;
            rw_stage2 <= 0;
            addr_stage2 <= 0;
            write_data_stage2 <= 0;
            mem_write_en_stage2 <= 0;
        end else begin
            state_stage2 <= state_stage1;
            busy_stage2 <= busy_stage1;
            rw_stage2 <= rw_stage1;
            addr_stage2 <= addr_stage1;
            write_data_stage2 <= write_data_stage1;
            mem_write_en_stage2 <= (state_stage1 == WRITE_STATE);
        end
    end
    
    // Stage 3: Memory access and response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3 <= IDLE;
            busy_stage3 <= 0;
            rw_stage3 <= 0;
            read_data_stage3 <= 0;
            done_stage3 <= 0;
        end else begin
            state_stage3 <= state_stage2;
            busy_stage3 <= busy_stage2;
            rw_stage3 <= rw_stage2;
            if (mem_ready && !rw_stage2)
                read_data_stage3 <= write_data_stage2;
            done_stage3 <= mem_ready;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state_stage1)
            IDLE: begin
                if (request_stage1)
                    next_state_stage1 = rw_stage1 ? WRITE_STATE : READ_STATE;
                else
                    next_state_stage1 = IDLE;
            end
            READ_STATE: next_state_stage1 = WAIT;
            WRITE_STATE: next_state_stage1 = WAIT;
            WAIT: next_state_stage1 = mem_ready ? IDLE : WAIT;
            default: next_state_stage1 = IDLE;
        endcase
    end
    
    // Output assignments
    always @(*) begin
        mem_addr = addr_stage2;
        mem_data = write_data_stage2;
        mem_write_en = mem_write_en_stage2;
        read_data = read_data_stage3;
        busy = busy_stage3;
        done = done_stage3;
    end
    
endmodule