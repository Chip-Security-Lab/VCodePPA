//SystemVerilog
module multi_filter_reset_detector(
  input  wire        clock,
  input  wire        reset_n,
  input  wire [3:0]  reset_sources,
  input  wire [3:0]  filter_enable,
  output wire [3:0]  filtered_resets
);

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : gen_reset_filter
      reset_filter #(
        .COUNTER_WIDTH(3),
        .MAX_COUNT(3'b111)
      ) u_reset_filter (
        .clk        (clock),
        .rst_n      (reset_n),
        .src        (reset_sources[i]),
        .en         (filter_enable[i]),
        .filtered   (filtered_resets[i])
      );
    end
  endgenerate

endmodule

module reset_filter #(
  parameter COUNTER_WIDTH = 3,
  parameter [COUNTER_WIDTH-1:0] MAX_COUNT = 3'b111
)(
  input  wire                      clk,
  input  wire                      rst_n,
  input  wire                      src,
  input  wire                      en,
  output reg                       filtered
);

  reg [COUNTER_WIDTH-1:0] filter_counter;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      filter_counter <= {COUNTER_WIDTH{1'b0}};
      filtered       <= 1'b0;
    end else begin
      if (en) begin
        if (src) begin
          if (filter_counter < MAX_COUNT)
            filter_counter <= filter_counter + 1'b1;
          else
            filter_counter <= MAX_COUNT;
        end else begin
          filter_counter <= {COUNTER_WIDTH{1'b0}};
        end
      end else begin
        filter_counter <= {COUNTER_WIDTH{1'b0}};
      end
      filtered <= (filter_counter == MAX_COUNT) ? 1'b1 : 1'b0;
    end
  end

endmodule