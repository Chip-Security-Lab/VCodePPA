//SystemVerilog
module bit_interleaver #(
    parameter WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input  [WIDTH-1:0]      data_a_in,
    input  [WIDTH-1:0]      data_b_in,
    input                   data_valid_in,
    output [2*WIDTH-1:0]    interleaved_data_out,
    output                  data_valid_out
);

    // Stage 1: Input register stage for data and valid
    reg [WIDTH-1:0] data_a_reg;
    reg [WIDTH-1:0] data_b_reg;
    reg             valid_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_a_reg <= {WIDTH{1'b0}};
            data_b_reg <= {WIDTH{1'b0}};
            valid_reg  <= 1'b0;
        end else begin
            data_a_reg <= data_a_in;
            data_b_reg <= data_b_in;
            valid_reg  <= data_valid_in;
        end
    end

    // Buffer register for valid_reg to reduce fanout
    reg valid_reg_buf;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_reg_buf <= 1'b0;
        else
            valid_reg_buf <= valid_reg;
    end

    // Buffer registers for interleaved_data_reg to reduce fanout
    reg [2*WIDTH-1:0] interleaved_data_reg;
    reg               interleaved_valid_reg;
    reg [2*WIDTH-1:0] interleaved_data_buf;
    reg               interleaved_valid_buf;

    // Buffer registers for loop variable i to reduce fanout in case of synthesis tool using i as a control signal
    reg [31:0] i_buf;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interleaved_data_reg  <= {2*WIDTH{1'b0}};
            interleaved_valid_reg <= 1'b0;
            i_buf                 <= 32'd0;
        end else begin
            for (i = 0; i < WIDTH; i = i + 1) begin
                interleaved_data_reg[2*i]   <= data_a_reg[i];
                interleaved_data_reg[2*i+1] <= data_b_reg[i];
            end
            interleaved_valid_reg <= valid_reg_buf;
            i_buf <= i;
        end
    end

    // Buffer stage for interleaved_data_reg and interleaved_valid_reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interleaved_data_buf  <= {2*WIDTH{1'b0}};
            interleaved_valid_buf <= 1'b0;
        end else begin
            interleaved_data_buf  <= interleaved_data_reg;
            interleaved_valid_buf <= interleaved_valid_reg;
        end
    end

    // Outputs from buffered registers
    assign interleaved_data_out = interleaved_data_buf;
    assign data_valid_out       = interleaved_valid_buf;

endmodule