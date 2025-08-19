//SystemVerilog
module can_transmitter(
  input clk, reset_n, tx_start,
  input [10:0] identifier,
  input [7:0] data_in,
  input [3:0] data_length,
  output reg tx_active, tx_done,
  output reg can_tx
);
  
  // 状态定义
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  
  // 寄存器定义
  reg [3:0] state, next_state;
  reg [7:0] bit_count, data_count;
  reg [14:0] crc, crc_next;
  
  // 流水线寄存器
  reg [3:0] state_pipe;
  reg [7:0] bit_count_pipe;
  reg tx_start_pipe;
  reg [10:0] identifier_pipe;
  reg [7:0] data_in_pipe;
  reg [3:0] data_length_pipe;
  
  // 状态转换查找表
  reg [3:0] state_transition_lut [0:8][0:15];
  
  // CRC更新控制表
  reg crc_update_enable;
  reg [1:0] crc_input_select;
  
  // 输出控制表
  reg can_tx_lut [0:8][0:15];
  reg bit_count_reset [0:8][0:15];
  reg bit_count_enable [0:8][0:15];
  reg data_count_enable [0:8][0:15];
  reg tx_active_ctrl [0:8][0:15];
  reg tx_done_ctrl [0:8][0:15];
  
  // 初始化状态转换表
  initial begin
    // 默认情况下所有状态都回到IDLE
    for (int i = 0; i < 9; i++) begin
      for (int j = 0; j < 16; j++) begin
        state_transition_lut[i][j] = IDLE;
      end
    end
    
    // IDLE状态
    state_transition_lut[IDLE][0] = IDLE;
    state_transition_lut[IDLE][1] = SOF;
    
    // SOF状态
    for (int j = 0; j < 16; j++) begin
      state_transition_lut[SOF][j] = ID;
    end
    
    // ID状态
    for (int j = 0; j < 11; j++) begin
      state_transition_lut[ID][j] = ID;
    end
    state_transition_lut[ID][11] = RTR;
    
    // RTR状态
    for (int j = 0; j < 16; j++) begin
      state_transition_lut[RTR][j] = CONTROL;
    end
    
    // CONTROL状态
    for (int j = 0; j < 6; j++) begin
      state_transition_lut[CONTROL][j] = CONTROL;
    end
    state_transition_lut[CONTROL][6] = DATA;
    
    // DATA状态
    // 实际转换逻辑在运行时根据data_length和bit_count计算
    
    // CRC状态
    for (int j = 0; j < 15; j++) begin
      state_transition_lut[CRC][j] = CRC;
    end
    state_transition_lut[CRC][15] = ACK;
    
    // ACK状态
    for (int j = 0; j < 2; j++) begin
      state_transition_lut[ACK][j] = ACK;
    end
    state_transition_lut[ACK][2] = EOF;
    
    // EOF状态
    for (int j = 0; j < 7; j++) begin
      state_transition_lut[EOF][j] = EOF;
    end
    state_transition_lut[EOF][7] = IDLE;
  end
  
  // 初始化输出控制表
  initial begin
    // 默认输出值
    for (int i = 0; i < 9; i++) begin
      for (int j = 0; j < 16; j++) begin
        can_tx_lut[i][j] = 1'b1;
        bit_count_reset[i][j] = 1'b0;
        bit_count_enable[i][j] = 1'b0;
        data_count_enable[i][j] = 1'b0;
        tx_active_ctrl[i][j] = 1'b0;
        tx_done_ctrl[i][j] = 1'b0;
      end
    end
    
    // IDLE状态输出
    tx_active_ctrl[IDLE][1] = 1'b1; // 当tx_start为1时激活tx_active
    bit_count_reset[IDLE][1] = 1'b1;
    
    // SOF状态输出
    for (int j = 0; j < 16; j++) begin
      can_tx_lut[SOF][j] = 1'b0; // SOF位为0
      bit_count_reset[SOF][j] = 1'b1;
    end
    
    // ID状态输出是动态的，由identifier决定
    // 在always块中处理
    for (int j = 0; j < 11; j++) begin
      bit_count_enable[ID][j] = 1'b1;
    end
    bit_count_reset[ID][11] = 1'b1;
    
    // RTR状态输出
    for (int j = 0; j < 16; j++) begin
      can_tx_lut[RTR][j] = 1'b0; // RTR位为0表示数据帧
      bit_count_reset[RTR][j] = 1'b1;
    end
    
    // CONTROL状态输出
    can_tx_lut[CONTROL][0] = 1'b0; // IDE位
    can_tx_lut[CONTROL][1] = 1'b0; // 保留位
    // DLC位在运行时设置
    for (int j = 0; j < 6; j++) begin
      bit_count_enable[CONTROL][j] = 1'b1;
    end
    bit_count_reset[CONTROL][6] = 1'b1;
    
    // DATA状态输出由data_in决定，在always块中设置
    for (int j = 0; j < 8; j++) begin
      bit_count_enable[DATA][j] = 1'b1;
    end
    bit_count_reset[DATA][7] = 1'b1;
    data_count_enable[DATA][7] = 1'b1;
    
    // CRC状态输出由crc寄存器决定，在always块中设置
    for (int j = 0; j < 15; j++) begin
      bit_count_enable[CRC][j] = 1'b1;
    end
    bit_count_reset[CRC][15] = 1'b1;
    
    // ACK状态输出
    can_tx_lut[ACK][0] = 1'b0; // ACK槽
    can_tx_lut[ACK][1] = 1'b1; // ACK分隔符
    bit_count_enable[ACK][0] = 1'b1;
    bit_count_reset[ACK][1] = 1'b1;
    
    // EOF状态输出
    for (int j = 0; j < 7; j++) begin
      can_tx_lut[EOF][j] = 1'b1; // EOF全为1
      bit_count_enable[EOF][j] = 1'b1;
    end
    tx_done_ctrl[EOF][6] = 1'b1;
    bit_count_reset[EOF][6] = 1'b1;
  end
  
  // 第一级流水线: 寄存状态和输入
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_pipe <= IDLE;
      bit_count_pipe <= 8'h0;
      tx_start_pipe <= 1'b0;
      identifier_pipe <= 11'b0;
      data_in_pipe <= 8'b0;
      data_length_pipe <= 4'b0;
    end
    else begin
      state_pipe <= state;
      bit_count_pipe <= bit_count;
      tx_start_pipe <= tx_start;
      identifier_pipe <= identifier;
      data_in_pipe <= data_in;
      data_length_pipe <= data_length;
    end
  end
  
  // 状态寄存器更新
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) state <= IDLE;
    else state <= next_state;
  end
  
  // CRC计算流水线
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc <= 15'h0;
    end
    else begin
      crc <= crc_next;
    end
  end
  
  // 下一状态查找表逻辑
  always @(*) begin
    if (state_pipe == DATA && data_count == data_length_pipe && bit_count_pipe == 8'd8)
      next_state = CRC;
    else if (state_pipe == DATA)
      next_state = DATA;
    else
      next_state = state_transition_lut[state_pipe][bit_count_pipe];
  end
  
  // CRC更新逻辑 - 使用选择器
  always @(*) begin
    // CRC更新控制
    crc_update_enable = 1'b0;
    crc_input_select = 2'b00;
    
    if (state_pipe == ID && bit_count_pipe < 8'd11) begin
      crc_update_enable = 1'b1;
      crc_input_select = 2'b01; // 使用identifier位
    end
    else if (state_pipe == DATA && data_count < data_length_pipe) begin
      crc_update_enable = 1'b1;
      crc_input_select = 2'b10; // 使用data_in位
    end
    
    // 默认保持当前CRC值
    crc_next = crc;
    
    // 根据选择器计算CRC
    if (crc_update_enable) begin
      case (crc_input_select)
        2'b01: crc_next = {crc[13:0], crc[14] ^ identifier_pipe[bit_count_pipe]};
        2'b10: crc_next = {crc[13:0], crc[14] ^ data_in_pipe[bit_count_pipe]};
        default: crc_next = crc;
      endcase
    end
  end
  
  // 输出逻辑和控制信号生成
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      can_tx <= 1'b1;
      tx_active <= 1'b0;
      tx_done <= 1'b0;
      bit_count <= 8'h0;
      data_count <= 8'h0;
    end
    else begin
      // 默认值
      tx_done <= 1'b0;
      
      // 通过查找表获取控制信号
      if (tx_start && state == IDLE)
        tx_active <= 1'b1;
      else if (state == EOF && bit_count == 8'd6)
        tx_active <= 1'b0;
      
      // 位计数器控制
      if (bit_count_reset[state][bit_count])
        bit_count <= 8'h0;
      else if (bit_count_enable[state][bit_count])
        bit_count <= bit_count + 8'h1;
      
      // 数据计数器控制
      if (state == IDLE && tx_start)
        data_count <= 8'h0;
      else if (state == DATA && bit_count == 8'd7 && data_count_enable[state][bit_count] && 
               data_count < data_length - 8'h1)
        data_count <= data_count + 8'h1;
      
      // 完成信号
      if (tx_done_ctrl[state][bit_count])
        tx_done <= 1'b1;
      
      // 输出信号控制
      case (state)
        ID: can_tx <= identifier[10-bit_count];
        CONTROL: begin
          if (bit_count >= 8'd2)
            can_tx <= data_length[bit_count-8'd2]; // DLC字段
          else
            can_tx <= can_tx_lut[state][bit_count];
        end
        DATA: can_tx <= data_in[7-bit_count];
        CRC: can_tx <= crc[14-bit_count];
        default: can_tx <= can_tx_lut[state][bit_count];
      endcase
    end
  end
  
endmodule