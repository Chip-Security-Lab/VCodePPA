//SystemVerilog
module twos_comp_to_sign_mag #(
    parameter WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   start,
    input  wire [WIDTH-1:0]       twos_comp_in,
    output wire [WIDTH-1:0]       sign_mag_out,
    output wire                   valid_out,
    input  wire                   flush
);

    // Pipeline Stage 1: Latch input and extract sign
    reg  [WIDTH-1:0]              twos_comp_stage1;
    reg                           sign_stage1;
    reg  [WIDTH-2:0]              data_stage1;
    reg                           valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            twos_comp_stage1 <= {WIDTH{1'b0}};
            sign_stage1      <= 1'b0;
            data_stage1      <= {(WIDTH-1){1'b0}};
            valid_stage1     <= 1'b0;
        end else if (start) begin
            twos_comp_stage1 <= twos_comp_in;
            sign_stage1      <= twos_comp_in[WIDTH-1];
            data_stage1      <= twos_comp_in[WIDTH-2:0];
            valid_stage1     <= 1'b1;
        end else begin
            valid_stage1     <= 1'b0;
        end
    end

    // Pipeline Stage 2: Calculate magnitude
    reg  [WIDTH-2:0]              magnitude_stage2;
    reg                           sign_stage2;
    reg                           valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            magnitude_stage2 <= {(WIDTH-1){1'b0}};
            sign_stage2      <= 1'b0;
            valid_stage2     <= 1'b0;
        end else begin
            sign_stage2      <= sign_stage1;
            magnitude_stage2 <= sign_stage1 ? (~data_stage1 + 1'b1) : data_stage1;
            valid_stage2     <= valid_stage1;
        end
    end

    // Pipeline Stage 3: Output register for sign-magnitude result
    reg  [WIDTH-1:0]              sign_mag_stage3;
    reg                           valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            sign_mag_stage3 <= {WIDTH{1'b0}};
            valid_stage3    <= 1'b0;
        end else begin
            sign_mag_stage3 <= {sign_stage2, magnitude_stage2};
            valid_stage3    <= valid_stage2;
        end
    end

    assign sign_mag_out = sign_mag_stage3;
    assign valid_out    = valid_stage3;

endmodule