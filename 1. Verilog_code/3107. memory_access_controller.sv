module memory_access_controller(
    input wire clk,
    input wire rst_n,
    input wire request,
    input wire rw, // 0: read, 1: write
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
    reg [1:0] state, next_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            mem_write_en <= 0;
        end else
            state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        mem_addr = addr;
        mem_data = write_data;
        
        case (state)
            IDLE: begin
                done = 0;
                if (request) begin
                    busy = 1;
                    if (rw)
                        next_state = WRITE_STATE;
                    else
                        next_state = READ_STATE;
                end else
                    busy = 0;
            end
            READ_STATE: begin
                mem_write_en = 0;
                next_state = WAIT;
            end
            WRITE_STATE: begin
                mem_write_en = 1;
                next_state = WAIT;
            end
            WAIT: begin
                if (mem_ready) begin
                    if (!rw)
                        read_data = mem_data;
                    done = 1;
                    busy = 0;
                    next_state = IDLE;
                end
            end
        endcase
    end
endmodule
