//SystemVerilog
// Top-level module
module state_machine_crc(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data,
    output wire [15:0] crc_out,
    output wire crc_ready
);
    // State definitions
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    
    // Internal signals
    wire [1:0] state, next_state;
    wire [3:0] bit_count;
    wire [15:0] crc_next;
    wire crc_ready_internal;
    
    // State controller submodule
    state_controller state_ctrl (
        .clk(clk),
        .rst(rst),
        .start(start),
        .bit_count(bit_count),
        .state(state),
        .next_state(next_state)
    );
    
    // Bit counter submodule
    bit_counter bit_cnt (
        .clk(clk),
        .rst(rst),
        .state(state),
        .bit_count(bit_count)
    );
    
    // CRC calculator submodule
    crc_calculator crc_calc (
        .clk(clk),
        .rst(rst),
        .state(state),
        .start(start),
        .data(data),
        .bit_count(bit_count),
        .crc_out(crc_out),
        .crc_next(crc_next)
    );
    
    // Output controller submodule
    output_controller out_ctrl (
        .clk(clk),
        .rst(rst),
        .state(state),
        .crc_ready(crc_ready)
    );
    
endmodule

// State controller submodule
module state_controller(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [3:0] bit_count,
    output reg [1:0] state,
    output reg [1:0] next_state
);
    // State definitions
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    
    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state; // Default: maintain current state
        
        case (state)
            IDLE: begin
                if (start) next_state = PROCESS;
            end
            PROCESS: begin
                if (bit_count == 4'd7) next_state = FINALIZE;
            end
            FINALIZE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
endmodule

// Bit counter submodule
module bit_counter(
    input wire clk,
    input wire rst,
    input wire [1:0] state,
    output reg [3:0] bit_count
);
    // State definitions
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    
    // Bit counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_count <= 4'd0;
        end else if (state == PROCESS) begin
            bit_count <= bit_count + 1;
        end else if (state == IDLE || state == FINALIZE) begin
            bit_count <= 4'd0;
        end
    end
    
endmodule

// CRC calculator submodule
module crc_calculator(
    input wire clk,
    input wire rst,
    input wire [1:0] state,
    input wire start,
    input wire [7:0] data,
    input wire [3:0] bit_count,
    output reg [15:0] crc_out,
    output wire [15:0] crc_next
);
    // State definitions
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    parameter [15:0] POLY = 16'h1021;
    
    // CRC calculation logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_out <= 16'hFFFF;
        end else if (state == PROCESS) begin
            crc_out <= crc_next;
        end else if (state == IDLE && start) begin
            crc_out <= 16'hFFFF; // Reset CRC value at start of new calculation
        end
    end
    
    // Next CRC value calculation
    assign crc_next = {crc_out[14:0], 1'b0} ^ 
                     ((crc_out[15] ^ data[bit_count]) ? POLY : 16'h0);
    
endmodule

// Output controller submodule
module output_controller(
    input wire clk,
    input wire rst,
    input wire [1:0] state,
    output reg crc_ready
);
    // State definitions
    parameter IDLE = 2'b00, PROCESS = 2'b01, FINALIZE = 2'b10;
    
    // Output control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_ready <= 1'b0;
        end else if (state == FINALIZE) begin
            crc_ready <= 1'b1;
        end else begin
            crc_ready <= 1'b0;
        end
    end
    
endmodule