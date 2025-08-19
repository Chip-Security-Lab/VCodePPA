//SystemVerilog
module bcd2bin_valid_ready (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [11:0]  bcd_in,
    input  wire         bcd_in_valid,
    output wire         bcd_in_ready,
    output wire [9:0]   bin_out,
    output wire         bin_out_valid,
    input  wire         bin_out_ready
);

    // Handshake signals
    wire           transfer_in;
    wire           transfer_out;

    // Register now holds the input BCD value only for handshake
    reg [11:0]     bcd_in_reg;
    reg            data_valid_reg;

    // Registered handshake for output
    reg            bin_out_valid_reg;

    // Output combinational logic
    reg [9:0]      bin_out_comb;

    // Registered output for valid and ready handshake
    reg [9:0]      bin_out_reg;

    assign transfer_in  = bcd_in_valid && bcd_in_ready;
    assign transfer_out = bin_out_valid_reg && bin_out_ready;

    // Input handshake logic
    assign bcd_in_ready = !data_valid_reg || (bin_out_valid_reg && bin_out_ready);

    // Output handshake logic
    assign bin_out      = bin_out_reg;
    assign bin_out_valid= bin_out_valid_reg;

    // Combinational BCD to Binary conversion
    always @* begin
        bin_out_comb = ({4'b0, bcd_in_reg[11:8]} * 8'd100)
                     + ({4'b0, bcd_in_reg[7:4]} * 4'd10)
                     + ({4'b0, bcd_in_reg[3:0]});
    end

    // Input data path and handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bcd_in_reg        <= 12'd0;
            data_valid_reg    <= 1'b0;
        end else begin
            // Accept new input if ready
            if (transfer_in) begin
                bcd_in_reg     <= bcd_in;
                data_valid_reg <= 1'b1;
            end else if (transfer_out) begin
                data_valid_reg <= 1'b0;
            end
        end
    end

    // Output handshake and register moved before combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_out_reg       <= 10'd0;
            bin_out_valid_reg <= 1'b0;
        end else begin
            if (data_valid_reg && (!bin_out_valid_reg || transfer_out)) begin
                bin_out_reg       <= bin_out_comb;
                bin_out_valid_reg <= 1'b1;
            end else if (transfer_out) begin
                bin_out_valid_reg <= 1'b0;
            end
        end
    end

endmodule