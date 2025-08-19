//SystemVerilog
// Top level module
module sample_hold_recovery (
    input wire clk,
    input wire rst_n,  // Added reset signal
    input wire sample_enable,
    input wire [11:0] analog_input,
    output wire [11:0] held_value,
    output wire hold_active,
    // Pipeline control signals
    input wire ready_in,
    output wire valid_out,
    output wire ready_out
);
    // Pipeline stage signals
    wire valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2;
    wire [11:0] data_stage1, data_stage2;
    wire hold_active_stage1;

    // Submodule instantiations
    input_sampler u_input_sampler (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_enable (sample_enable),
        .analog_input  (analog_input),
        .sampled_data  (data_stage1),
        .sample_valid  (valid_stage1),
        .ready_in      (ready_in),
        .ready_out     (ready_stage1)
    );

    pipeline_register u_pipeline_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .valid_in    (valid_stage1),
        .ready_in    (ready_stage2),
        .data_in     (data_stage1),
        .valid_out   (valid_stage2),
        .ready_out   (ready_stage1),
        .data_out    (data_stage2)
    );

    value_holder u_value_holder (
        .clk           (clk),
        .rst_n         (rst_n),
        .sample_valid  (valid_stage2),
        .sampled_data  (data_stage2),
        .held_value    (held_value),
        .hold_active   (hold_active),
        .valid_out     (valid_out),
        .ready_in      (ready_in),
        .ready_out     (ready_stage2)
    );

    assign ready_out = ready_stage1;
endmodule

// Pipeline register module
module pipeline_register (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire ready_in,
    input wire [11:0] data_in,
    output reg valid_out,
    output wire ready_out,
    output reg [11:0] data_out
);
    wire transfer;
    assign transfer = valid_in && ready_out;
    assign ready_out = !valid_out || ready_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
            data_out <= 12'b0;
        end else if (ready_in || !valid_out) begin
            if (transfer) begin
                data_out <= data_in;
                valid_out <= 1'b1;
            end else if (ready_in && valid_out) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule

// Input sampling module
module input_sampler (
    input wire clk,
    input wire rst_n,
    input wire sample_enable,
    input wire [11:0] analog_input,
    output reg [11:0] sampled_data,
    output reg sample_valid,
    input wire ready_in,
    output wire ready_out
);
    // Ready to accept data when downstream is ready or no valid data
    assign ready_out = 1'b1;  // Always ready to sample new data

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sampled_data <= 12'b0;
            sample_valid <= 1'b0;
        end else if (ready_in) begin
            if (sample_enable) begin
                sampled_data <= analog_input;
                sample_valid <= 1'b1;
            end else begin
                sample_valid <= 1'b0;
            end
        end
    end
endmodule

// Value holding module
module value_holder (
    input wire clk,
    input wire rst_n,
    input wire sample_valid,
    input wire [11:0] sampled_data,
    output reg [11:0] held_value,
    output reg hold_active,
    output wire valid_out,
    input wire ready_in,
    output wire ready_out
);
    // Pipeline control logic
    reg processing_stage1;
    reg [11:0] internal_value;
    
    assign ready_out = !processing_stage1 || ready_in;
    assign valid_out = hold_active;

    // First pipeline stage - receive and register data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing_stage1 <= 1'b0;
            internal_value <= 12'b0;
        end else if (ready_out) begin
            if (sample_valid) begin
                internal_value <= sampled_data;
                processing_stage1 <= 1'b1;
            end else begin
                processing_stage1 <= 1'b0;
            end
        end
    end

    // Second pipeline stage - update held value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            held_value <= 12'b0;
            hold_active <= 1'b0;
        end else if (ready_in) begin
            if (processing_stage1) begin
                held_value <= internal_value;
                hold_active <= 1'b1;
            end
        end
    end
endmodule