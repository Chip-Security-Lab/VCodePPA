//SystemVerilog
module dynamic_priority_arbiter(
  input wire clk, rst_n,
  input wire [7:0] valid,
  input wire [23:0] dynamic_priority,
  output reg [7:0] grants,
  output reg ready
);

  wire [2:0] priority_array [0:7];
  reg [7:0] masked_valid;
  reg [2:0] current_pri;
  reg [2:0] highest_pri;
  reg valid_handled;
  
  assign priority_array[0] = dynamic_priority[2:0];
  assign priority_array[1] = dynamic_priority[5:3];
  assign priority_array[2] = dynamic_priority[8:6];
  assign priority_array[3] = dynamic_priority[11:9];
  assign priority_array[4] = dynamic_priority[14:12];
  assign priority_array[5] = dynamic_priority[17:15];
  assign priority_array[6] = dynamic_priority[20:18];
  assign priority_array[7] = dynamic_priority[23:21];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grants <= 8'b0;
      ready <= 1'b0;
      valid_handled <= 1'b0;
    end
    else begin
      if (|valid && !valid_handled) begin
        grants <= 8'b0;
        current_pri = 3'b0;
        highest_pri = 3'b0;
        
        if (valid[0] && (priority_array[0] > current_pri)) begin
          current_pri = priority_array[0];
          highest_pri = 3'd0;
        end
        if (valid[1] && (priority_array[1] > current_pri)) begin
          current_pri = priority_array[1];
          highest_pri = 3'd1;
        end
        if (valid[2] && (priority_array[2] > current_pri)) begin
          current_pri = priority_array[2];
          highest_pri = 3'd2;
        end
        if (valid[3] && (priority_array[3] > current_pri)) begin
          current_pri = priority_array[3];
          highest_pri = 3'd3;
        end
        if (valid[4] && (priority_array[4] > current_pri)) begin
          current_pri = priority_array[4];
          highest_pri = 3'd4;
        end
        if (valid[5] && (priority_array[5] > current_pri)) begin
          current_pri = priority_array[5];
          highest_pri = 3'd5;
        end
        if (valid[6] && (priority_array[6] > current_pri)) begin
          current_pri = priority_array[6];
          highest_pri = 3'd6;
        end
        if (valid[7] && (priority_array[7] > current_pri)) begin
          current_pri = priority_array[7];
          highest_pri = 3'd7;
        end
        
        grants[highest_pri] <= 1'b1;
        ready <= 1'b1;
        valid_handled <= 1'b1;
      end
      else if (!(|valid)) begin
        grants <= 8'b0;
        ready <= 1'b0;
        valid_handled <= 1'b0;
      end
    end
  end
endmodule