//SystemVerilog
module moore_4state_ring #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output [WIDTH-1:0] ring_out
);
  wire [1:0] state_stage1;
  wire [1:0] state_stage2;
  wire [WIDTH-1:0] ring_out_stage1;
  
  // 实例化状态控制子模块
  state_controller state_ctrl_inst (
    .clk(clk),
    .rst(rst),
    .state(state_stage1)
  );
  
  // 流水线寄存器
  reg [1:0] state_reg;
  reg [WIDTH-1:0] ring_out_reg;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_reg <= 2'b00;
      ring_out_reg <= {WIDTH{1'b0}};
    end else begin
      state_reg <= state_stage1;
      ring_out_reg <= ring_out_stage1;
    end
  end
  
  // 实例化输出解码子模块
  output_decoder #(.WIDTH(WIDTH)) output_dec_inst (
    .state(state_reg),
    .ring_out(ring_out)
  );
  
endmodule

module state_controller (
  input  clk,
  input  rst,
  output reg [1:0] state
);
  reg [1:0] next_state;
  reg [1:0] state_reg;
  
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_reg <= S0;
      state <= S0;
    end else begin
      state_reg <= next_state;
      state <= state_reg;
    end
  end

  always @* begin
    case (state_reg)
      S0: next_state = S1;
      S1: next_state = S2;
      S2: next_state = S3;
      S3: next_state = S0;
      default: next_state = S0;
    endcase
  end
endmodule

module output_decoder #(parameter WIDTH = 4)(
  input  [1:0] state,
  output reg [WIDTH-1:0] ring_out
);
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;

  always @* begin
    case (state)
      S0: ring_out = {{(WIDTH-1){1'b0}}, 1'b1};
      S1: ring_out = {{(WIDTH-2){1'b0}}, 1'b1, 1'b0};
      S2: ring_out = {{(WIDTH-3){1'b0}}, 1'b1, {2{1'b0}}};
      S3: ring_out = {{(WIDTH-4){1'b0}}, 1'b1, {3{1'b0}}};
      default: ring_out = {{(WIDTH-1){1'b0}}, 1'b1};
    endcase
  end
endmodule