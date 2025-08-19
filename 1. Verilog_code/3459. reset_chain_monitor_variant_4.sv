//SystemVerilog
// Top-level module
module reset_chain_monitor (
  input  wire       clk,
  input  wire [3:0] reset_chain,
  input  wire       ready,         // 新增：接收方准备好接收数据
  output wire       valid,         // 新增：数据有效信号
  output wire       reset_chain_error
);
  
  // Internal signals for connecting submodules
  wire reset_chain_valid;
  wire validator_valid;
  wire detector_ready;
  
  // Submodule instantiations
  reset_chain_validator validator (
    .clk           (clk),
    .reset_chain   (reset_chain),
    .ready         (detector_ready),
    .valid         (validator_valid),
    .chain_valid   (reset_chain_valid)
  );
  
  error_detector detector (
    .clk           (clk),
    .chain_valid   (reset_chain_valid),
    .valid         (validator_valid),
    .ready         (detector_ready),
    .error_flag    (reset_chain_error)
  );
  
  // Top level valid signal
  assign valid = reset_chain_error;
  
endmodule

// Submodule for validating reset chain values
module reset_chain_validator (
  input  wire       clk,
  input  wire [3:0] reset_chain,
  input  wire       ready,         // 新增：下游模块准备好接收数据
  output reg        valid,         // 新增：数据有效信号
  output reg        chain_valid
);
  
  // Parameters for valid reset chain patterns
  localparam RESET_ACTIVE   = 4'b0000;
  localparam RESET_INACTIVE = 4'b1111;
  
  // Check if reset chain has valid pattern and generate valid signal
  always @(posedge clk) begin
    chain_valid <= (reset_chain == RESET_ACTIVE || reset_chain == RESET_INACTIVE);
    valid <= 1'b1;  // 数据总是有效，可以根据具体需求修改
    
    // 当握手完成后，可以准备下一个数据周期
    if (valid && ready) begin
      valid <= 1'b0;  // 握手完成后重置valid信号
    end
  end
  
endmodule

// Submodule for error detection and flagging
module error_detector (
  input  wire clk,
  input  wire chain_valid,
  input  wire valid,         // 新增：上游数据有效
  output reg  ready,         // 新增：准备好接收数据
  output reg  error_flag
);
  
  // Error detection logic with valid-ready handshake
  always @(posedge clk) begin
    // 默认准备好接收数据
    ready <= 1'b1;
    
    // 只在数据有效时处理
    if (valid && ready) begin
      if (!chain_valid) begin
        error_flag <= 1'b1;
      end
      
      // 握手完成，标记已处理
      ready <= 1'b0;
    end else begin
      // 未处于握手状态，恢复ready信号
      ready <= 1'b1;
    end
  end
  
endmodule