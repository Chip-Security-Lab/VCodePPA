//SystemVerilog
module moore_4state_1010_seq_detector(
  input  clk,
  input  rst,
  input  in,
  input  req,
  output reg ack,
  output reg found
);
  reg [1:0] state, next_state;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;
  
  reg req_reg;
  reg processing;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= S0;
      req_reg <= 1'b0;
      processing <= 1'b0;
      ack <= 1'b0;
    end
    else begin
      state <= next_state;
      req_reg <= req;
      
      // Request-acknowledge handshake logic
      if (req && !req_reg && !processing) begin
        processing <= 1'b1;
        ack <= 1'b1;
      end
      else if (!req && req_reg) begin
        processing <= 1'b0;
        ack <= 1'b0;
      end
    end
  end

  always @* begin
    case (state)
      S0: next_state = in ? S1 : S0;
      S1: next_state = in ? S1 : S2;
      S2: next_state = in ? S3 : S0;
      S3: next_state = in ? S1 : S2;
    endcase
  end

  // Moore output: 在状态S3时且当前输入为0，表示检测到"1010"
  always @* found = (state == S3 && in == 1'b0);
endmodule