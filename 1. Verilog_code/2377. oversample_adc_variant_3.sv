//SystemVerilog
// Top level module
module oversample_adc (
    input  wire       clk,       // Clock signal
    input  wire       rst_n,     // Reset signal (active low)
    input  wire       adc_in,    // ADC input signal
    input  wire       ready,     // Ready signal from receiver
    output wire       valid,     // Valid signal to receiver
    output wire [7:0] adc_out    // ADC output data
);

    // Internal signals
    wire [2:0] sum_out;
    wire [2:0] count_out;
    wire       sample_complete;
    wire [7:0] adc_sample;
    wire       data_ready;

    // Sampling unit - handles input sampling and counting
    sample_unit u_sample_unit (
        .clk            (clk),
        .rst_n          (rst_n),
        .adc_in         (adc_in),
        .sum_out        (sum_out),
        .count_out      (count_out),
        .sample_complete(sample_complete)
    );

    // Processing unit - handles data conversion and preparation
    processing_unit u_processing_unit (
        .clk            (clk),
        .rst_n          (rst_n),
        .sum_in         (sum_out),
        .sample_complete(sample_complete),
        .adc_sample     (adc_sample),
        .data_ready     (data_ready)
    );

    // Output interface - handles handshaking with receiver
    output_interface u_output_interface (
        .clk        (clk),
        .rst_n      (rst_n),
        .adc_sample (adc_sample),
        .data_ready (data_ready),
        .ready      (ready),
        .valid      (valid),
        .adc_out    (adc_out)
    );

endmodule

// Submodule for handling ADC sampling and counting
module sample_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       adc_in,
    output reg  [2:0] sum_out,
    output reg  [2:0] count_out,
    output wire       sample_complete
);

    // Sample complete flag when count reaches 111
    assign sample_complete = &count_out;

    // Sampling and counting logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_out   <= 3'b000;
            count_out <= 3'b000;
        end else begin
            // Accumulate input samples
            sum_out <= sample_complete ? 3'b000 : (sum_out + adc_in);
            
            // Increment counter, reset when complete
            count_out <= sample_complete ? 3'b000 : (count_out + 1'b1);
        end
    end

endmodule

// Submodule for processing the sampled data
module processing_unit (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] sum_in,
    input  wire       sample_complete,
    output reg  [7:0] adc_sample,
    output reg        data_ready
);

    // Process accumulated samples into output data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adc_sample <= 8'b0;
            data_ready <= 1'b0;
        end else begin
            // Generate new sample when complete
            if (sample_complete) begin
                adc_sample <= {sum_in, 5'b00000};  // Shift left by 5
                data_ready <= 1'b1;
            end else if (data_ready && adc_sample != 8'b0) begin
                // Keep data_ready high until handshake completes in output_interface
                data_ready <= 1'b1;
            end else begin
                data_ready <= 1'b0;
            end
        end
    end

endmodule

// Submodule for handling output interface and handshaking
module output_interface (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] adc_sample,
    input  wire       data_ready,
    input  wire       ready,
    output reg        valid,
    output reg  [7:0] adc_out
);

    // Handle handshaking with receiver
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid   <= 1'b0;
            adc_out <= 8'b0;
        end else begin
            // Set valid when data is ready
            valid <= data_ready;
            
            // Update output when handshake occurs
            if (data_ready && ready) begin
                adc_out <= adc_sample;
            end
        end
    end

endmodule