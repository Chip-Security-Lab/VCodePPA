//SystemVerilog
module bin2gray #(parameter WIDTH = 8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [WIDTH-1:0]      bin_in,
    output wire [WIDTH-1:0]      gray_out
);

    // Pipeline stage 1: Register the binary input
    reg [WIDTH-1:0] bin_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_stage1 <= {WIDTH{1'b0}};
        else
            bin_stage1 <= bin_in;
    end

    // Pipeline stage 2: Compute gray code combinationally
    reg [WIDTH-1:0] gray_stage2;
    integer i;
    always @* begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (i == (WIDTH-1))
                gray_stage2[i] = bin_stage1[i];
            else
                gray_stage2[i] = bin_stage1[i] ^ bin_stage1[i+1];
        end
    end

    // Pipeline stage 3: Register the gray code output
    reg [WIDTH-1:0] gray_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_stage3 <= {WIDTH{1'b0}};
        else
            gray_stage3 <= gray_stage2;
    end

    assign gray_out = gray_stage3;

endmodule