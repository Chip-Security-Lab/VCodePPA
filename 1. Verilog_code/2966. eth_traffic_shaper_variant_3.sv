//SystemVerilog
module eth_traffic_shaper #(
    parameter RATE_MBPS = 1000,
    parameter BURST_BYTES = 16384
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        in_valid,
    output wire [7:0]  data_out,
    output wire        out_valid,
    output wire        credit_overflow
);
    // Internal signals for module interconnection
    wire [31:0] token_counter;
    wire [31:0] byte_counter;
    wire [1:0]  shaper_state;
    wire        token_update_condition;
    wire [7:0]  data_in_reg;
    wire        in_valid_reg;
    
    // Input stage module
    input_stage input_stage_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .data_in       (data_in),
        .in_valid      (in_valid),
        .data_in_reg   (data_in_reg),
        .in_valid_reg  (in_valid_reg)
    );
    
    // Token bucket module
    token_bucket #(
        .RATE_MBPS     (RATE_MBPS),
        .BURST_BYTES   (BURST_BYTES)
    ) token_bucket_inst (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .token_update_condition(token_update_condition),
        .shaper_state          (shaper_state),
        .token_counter         (token_counter),
        .credit_overflow       (credit_overflow)
    );
    
    // Timing control module
    timing_control timing_control_inst (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .byte_counter          (byte_counter),
        .token_update_condition(token_update_condition)
    );
    
    // State controller module
    state_controller state_controller_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .in_valid_reg  (in_valid_reg),
        .token_counter (token_counter),
        .shaper_state  (shaper_state)
    );
    
    // Output stage module
    output_stage output_stage_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .shaper_state  (shaper_state),
        .token_counter (token_counter),
        .data_in_reg   (data_in_reg),
        .out_valid     (out_valid),
        .data_out      (data_out)
    );

endmodule

// Input stage module - handles input registration
module input_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        in_valid,
    output reg  [7:0]  data_in_reg,
    output reg         in_valid_reg
);
    // Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'b0;
            in_valid_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            in_valid_reg <= in_valid;
        end
    end
endmodule

// Token bucket module - manages token allocation and consumption
module token_bucket #(
    parameter RATE_MBPS = 1000,
    parameter BURST_BYTES = 16384
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        token_update_condition,
    input  wire [1:0]  shaper_state,
    output reg  [31:0] token_counter,
    output reg         credit_overflow
);
    localparam TOKEN_INC = RATE_MBPS * 1000 / 8;  // Bytes per us
    
    // Internal wires
    wire [31:0] next_token_counter;
    wire        next_credit_overflow;
    
    // Calculate next token counter value
    assign next_token_counter = (!rst_n) ? BURST_BYTES :
                               (token_update_condition) ? 
                               ((token_counter + TOKEN_INC > BURST_BYTES) ? BURST_BYTES : token_counter + TOKEN_INC) :
                               ((shaper_state == 2'b01 && token_counter > 0) ? token_counter - 1 : token_counter);
    
    // Calculate next credit overflow
    assign next_credit_overflow = (!rst_n) ? 1'b0 : (next_token_counter == BURST_BYTES);
    
    // Update token counter and credit overflow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_counter <= BURST_BYTES;
            credit_overflow <= 1'b0;
        end else begin
            token_counter <= next_token_counter;
            credit_overflow <= next_credit_overflow;
        end
    end
endmodule

// Timing control module - manages microsecond timing
module timing_control (
    input  wire        clk,
    input  wire        rst_n,
    output reg  [31:0] byte_counter,
    output wire        token_update_condition
);
    // Determine if tokens should be updated (1 us @ 125MHz)
    assign token_update_condition = (byte_counter >= 32'd125000);
    
    // Update byte counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter <= 32'b0;
        end else begin
            byte_counter <= token_update_condition ? 32'b0 : byte_counter + 1'b1;
        end
    end
endmodule

// State controller module - manages traffic shaper state machine
module state_controller (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid_reg,
    input  wire [31:0] token_counter,
    output reg  [1:0]  shaper_state
);
    // Internal wire
    wire [1:0] next_shaper_state;
    
    // Calculate next shaper state
    assign next_shaper_state = (!rst_n) ? 2'b00 :
                              (shaper_state == 2'b00 && in_valid_reg) ? 2'b01 :
                              (shaper_state == 2'b01 && token_counter > 0) ? 2'b10 :
                              (shaper_state == 2'b10) ? 2'b00 : shaper_state;
    
    // Update state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shaper_state <= 2'b00;
        end else begin
            shaper_state <= next_shaper_state;
        end
    end
endmodule

// Output stage module - manages output signals
module output_stage (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  shaper_state,
    input  wire [31:0] token_counter,
    input  wire [7:0]  data_in_reg,
    output reg         out_valid,
    output reg  [7:0]  data_out
);
    // Internal wires
    wire        next_out_valid;
    wire [7:0]  next_data_out;
    
    // Calculate next output valid
    assign next_out_valid = (!rst_n) ? 1'b0 :
                           (shaper_state == 2'b01 && token_counter > 0) ? 1'b1 :
                           (shaper_state == 2'b10) ? 1'b0 : out_valid;
    
    // Calculate next data out
    assign next_data_out = (!rst_n) ? 8'b0 :
                          (shaper_state == 2'b01 && token_counter > 0) ? data_in_reg : data_out;
    
    // Update output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            data_out <= 8'b0;
        end else begin
            out_valid <= next_out_valid;
            data_out <= next_data_out;
        end
    end
endmodule