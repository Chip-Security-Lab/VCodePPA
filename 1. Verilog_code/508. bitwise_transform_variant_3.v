module bitwise_transform #(
    parameter DATA_WIDTH = 4
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  valid_in,
    output reg                   ready_out,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg                   valid_out,
    input  wire                  ready_in,
    output reg  [DATA_WIDTH-1:0] data_out
);

    // Pipeline stage registers
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg                 valid_stage1;
    reg                 valid_stage2;
    reg                 ready_stage1;
    reg                 ready_stage2;
    
    // Stage 1: Input register and bit reordering with two's complement subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (valid_in && ready_stage1) begin
            // Two's complement subtraction: A - B = A + (~B + 1)
            data_stage1 <= {data_in[0], data_in[1], data_in[2], data_in[3]} + 1'b1;
            valid_stage1 <= 1'b1;
        end else if (!ready_stage1) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && ready_stage2) begin
            data_stage2 <= data_stage1;
            valid_stage2 <= 1'b1;
        end else if (!ready_stage2) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Backpressure logic
    always @(*) begin
        ready_stage1 = !valid_stage1 || ready_stage2;
        ready_stage2 = !valid_stage2 || ready_in;
        ready_out = ready_stage1;
    end
    
    // Output assignment
    always @(*) begin
        data_out = data_stage2;
        valid_out = valid_stage2;
    end

endmodule