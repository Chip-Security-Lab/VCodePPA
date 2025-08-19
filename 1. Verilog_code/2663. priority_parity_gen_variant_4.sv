//SystemVerilog
module priority_parity_gen(
  input wire clk,
  input wire rst_n,
  input wire [15:0] data,
  input wire [3:0] priority_level,
  input wire req,         // 请求信号，发送方请求处理数据
  output reg ack,         // 应答信号，表示已完成处理
  output reg parity_result
);
  
  reg processing;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ack <= 1'b0;
      processing <= 1'b0;
      parity_result <= 1'b0;
    end else begin
      // 检测新的请求
      if (req && !processing && !ack) begin
        processing <= 1'b1;
        
        // 执行奇偶校验计算
        case(priority_level)
          4'h0: parity_result <= ^data[15:0];
          4'h1: parity_result <= ^data[15:1];
          4'h2: parity_result <= ^data[15:2];
          4'h3: parity_result <= ^data[15:3];
          4'h4: parity_result <= ^data[15:4];
          4'h5: parity_result <= ^data[15:5];
          4'h6: parity_result <= ^data[15:6];
          4'h7: parity_result <= ^data[15:7];
          4'h8: parity_result <= ^data[15:8];
          4'h9: parity_result <= ^data[15:9];
          4'hA: parity_result <= ^data[15:10];
          4'hB: parity_result <= ^data[15:11];
          4'hC: parity_result <= ^data[15:12];
          4'hD: parity_result <= ^data[15:13];
          4'hE: parity_result <= ^data[15:14];
          4'hF: parity_result <= data[15];
          default: parity_result <= ^data[15:0];
        endcase
        
        ack <= 1'b1;  // 发送应答信号
      end
      // 重置处理状态，等待req信号撤销
      else if (ack && !req) begin
        ack <= 1'b0;
        processing <= 1'b0;
      end
    end
  end

endmodule