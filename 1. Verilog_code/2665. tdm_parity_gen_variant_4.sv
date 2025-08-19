//SystemVerilog
// Stream selector module with improved PPA
module stream_selector(
  input clk, rst_n,
  input [7:0] stream_a, stream_b,
  input stream_sel,
  output reg [7:0] selected_stream
);
  // Use combinational logic for selection to reduce latency
  wire [7:0] next_stream = stream_sel ? stream_b : stream_a;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      selected_stream <= 8'h0;
    end else begin
      selected_stream <= next_stream;
    end
  end
endmodule

// Optimized parity calculation module
module parity_calculator(
  input clk, rst_n,
  input [7:0] data_in,
  output reg parity_out
);
  // Pre-calculate parity to reduce critical path
  wire next_parity = ^data_in;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= next_parity;
    end
  end
endmodule

// Top-level module with improved timing
module tdm_parity_gen(
  input clk, rst_n,
  input [7:0] stream_a, stream_b,
  input stream_sel,
  output parity_out
);
  wire [7:0] selected_stream;
  
  stream_selector selector_inst(
    .clk(clk),
    .rst_n(rst_n),
    .stream_a(stream_a),
    .stream_b(stream_b),
    .stream_sel(stream_sel),
    .selected_stream(selected_stream)
  );
  
  parity_calculator parity_inst(
    .clk(clk),
    .rst_n(rst_n),
    .data_in(selected_stream),
    .parity_out(parity_out)
  );
endmodule