//SystemVerilog
module parity_corrector (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    output wire [7:0]  data_out,
    output wire        error
);

    // Stage 1: Parity Calculation and Latching
    // -----------------------------------------
    // Calculate parity for input data and register the result.
    // This stage isolates the parity logic and provides a clean pipeline boundary.
    reg         parity_stage1_reg;
    reg [7:0]   data_stage1_reg;

    wire        parity_stage1;
    assign      parity_stage1 = ^data_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_stage1_reg <= 1'b0;
            data_stage1_reg   <= 8'b0;
        end else begin
            parity_stage1_reg <= parity_stage1;
            data_stage1_reg   <= data_in;
        end
    end

    // Stage 2: Data Correction (Registered)
    // -------------------------------------
    // Based on the registered parity, either correct data or pass through.
    reg [7:0]   data_stage2_reg;
    reg         error_stage2_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2_reg   <= 8'b0;
            error_stage2_reg  <= 1'b0;
        end else begin
            if (parity_stage1_reg) begin
                data_stage2_reg  <= 8'h00;
            end else begin
                data_stage2_reg  <= data_stage1_reg;
            end
            error_stage2_reg <= parity_stage1_reg;
        end
    end

    // Stage 3: Output Register (Optional for Timing Closure)
    // -----------------------------------------------------
    reg [7:0]   data_out_reg;
    reg         error_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg  <= 8'b0;
            error_out_reg <= 1'b0;
        end else begin
            data_out_reg  <= data_stage2_reg;
            error_out_reg <= error_stage2_reg;
        end
    end

    // Outputs
    assign data_out = data_out_reg;
    assign error    = error_out_reg;

endmodule