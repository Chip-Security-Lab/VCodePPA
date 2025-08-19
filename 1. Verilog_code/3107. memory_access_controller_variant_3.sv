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
    reg [1:0] state, next_state;
    reg [1:0] state_d1;
    reg [7:0] addr_d1;
    reg [15:0] write_data_d1;
    reg rw_d1;
    reg request_d1;
    
    // Karatsuba multiplier signals
    wire [15:0] a_high, a_low, b_high, b_low;
    wire [15:0] z0, z1, z2;
    wire [31:0] result;
    
    // Split inputs into high and low parts
    assign a_high = write_data_d1[15:8];
    assign a_low = write_data_d1[7:0];
    assign b_high = addr_d1[7:4];
    assign b_low = addr_d1[3:0];
    
    // Karatsuba multiplier implementation
    karatsuba_multiplier #(.WIDTH(8)) mult0 (
        .a(a_low),
        .b(b_low),
        .result(z0)
    );
    
    karatsuba_multiplier #(.WIDTH(8)) mult1 (
        .a(a_high),
        .b(b_high),
        .result(z1)
    );
    
    karatsuba_multiplier #(.WIDTH(8)) mult2 (
        .a(a_high + a_low),
        .b(b_high + b_low),
        .result(z2)
    );
    
    // Final result calculation
    assign result = (z1 << 16) + ((z2 - z1 - z0) << 8) + z0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            state_d1 <= IDLE;
            busy <= 0;
            done <= 0;
            mem_write_en <= 0;
            addr_d1 <= 0;
            write_data_d1 <= 0;
            rw_d1 <= 0;
            request_d1 <= 0;
        end else begin
            state <= next_state;
            state_d1 <= state;
            addr_d1 <= addr;
            write_data_d1 <= write_data;
            rw_d1 <= rw;
            request_d1 <= request;
        end
    end
    
    always @(*) begin
        next_state = state;
        mem_addr = addr_d1;
        mem_data = result[15:0];
        
        case (state_d1)
            IDLE: begin
                done = 0;
                if (request_d1) begin
                    busy = 1;
                    if (rw_d1)
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
                    if (!rw_d1)
                        read_data = mem_data;
                    done = 1;
                    busy = 0;
                    next_state = IDLE;
                end
            end
        endcase
    end
endmodule

module karatsuba_multiplier #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [2*WIDTH-1:0] result
);
    wire [WIDTH/2-1:0] a_high, a_low, b_high, b_low;
    wire [WIDTH-1:0] z0, z1, z2;
    
    assign a_high = a[WIDTH-1:WIDTH/2];
    assign a_low = a[WIDTH/2-1:0];
    assign b_high = b[WIDTH-1:WIDTH/2];
    assign b_low = b[WIDTH/2-1:0];
    
    assign z0 = a_low * b_low;
    assign z1 = a_high * b_high;
    assign z2 = (a_high + a_low) * (b_high + b_low);
    
    assign result = (z1 << WIDTH) + ((z2 - z1 - z0) << (WIDTH/2)) + z0;
endmodule