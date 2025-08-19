//SystemVerilog
// Top module: manchester_encoder_valid_ready
module manchester_encoder_valid_ready (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid,
    input  wire        data_in,
    output reg         data_ready,
    output reg         manchester_out,
    output reg         manchester_valid,
    input  wire        manchester_ready
);

    reg                half_bit;
    reg                data_in_reg;
    reg                data_buffered;

    // --------------------------------------------------------------------------
    // Asynchronous Reset and Data Buffering Logic
    // Handles data input latching and buffer state
    // --------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg      <= 1'b0;
            data_buffered    <= 1'b0;
            half_bit         <= 1'b0;
        end else begin
            // Latch input data and mark buffer as full on valid/ready handshake
            if (data_valid && data_ready) begin
                data_in_reg   <= data_in;
                data_buffered <= 1'b1;
                half_bit      <= 1'b0;
            end
            // Release buffer when a full Manchester cycle is completed
            else if (data_buffered && (manchester_ready || !manchester_valid) && half_bit) begin
                data_buffered <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Data Ready Signal Logic
    // Indicates readiness to accept new data when not buffering
    // --------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_ready <= 1'b1;
        end else begin
            data_ready <= ~data_buffered;
        end
    end

    // --------------------------------------------------------------------------
    // Manchester Output Generation Logic
    // Generates Manchester code and toggles half_bit
    // --------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manchester_out   <= 1'b0;
            half_bit         <= 1'b0;
        end else begin
            if (data_buffered && (manchester_ready || !manchester_valid)) begin
                half_bit <= ~half_bit;
                if (!half_bit)
                    manchester_out <= data_in_reg ? 1'b0 : 1'b1;
                else
                    manchester_out <= data_in_reg ? 1'b1 : 1'b0;
            end
        end
    end

    // --------------------------------------------------------------------------
    // Manchester Valid Output Logic
    // Controls valid assertion and de-assertion for output handshake
    // --------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manchester_valid <= 1'b0;
        end else begin
            if (data_buffered && (manchester_ready || !manchester_valid)) begin
                manchester_valid <= 1'b1;
            end else if (!data_buffered || (data_buffered && (manchester_ready || !manchester_valid) && half_bit)) begin
                manchester_valid <= 1'b0;
            end
        end
    end

endmodule