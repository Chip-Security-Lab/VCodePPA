module mipi_rffe_controller (
  input wire clk, reset_n,
  input wire [7:0] command,
  input wire [7:0] address,
  input wire [7:0] write_data,
  input wire start_transaction, is_write,
  output reg sclk, sdata,
  output reg busy, done
);
  localparam IDLE = 3'd0, START = 3'd1, CMD = 3'd2, ADDR = 3'd3;
  localparam DATA = 3'd4, PARITY = 3'd5, END = 3'd6;
  
  reg [2:0] state;
  reg [3:0] bit_count;
  reg parity;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      sclk <= 1'b1;
      sdata <= 1'b1;
      busy <= 1'b0;
      done <= 1'b0;
      bit_count <= 4'd0;
      parity <= 1'b0;
    end else begin
      case (state)
        IDLE: begin
          if (start_transaction) begin 
            state <= START; 
            busy <= 1'b1;
            done <= 1'b0;
            parity <= 1'b0;
          end
        end
        
        START: begin
          sdata <= 1'b0; 
          state <= CMD; 
          bit_count <= 4'd7;
        end
        
        CMD: begin
          sdata <= command[bit_count];
          parity <= parity ^ command[bit_count];
          if (bit_count == 0) begin
            state <= ADDR; 
            bit_count <= 4'd7;
          end else begin
            bit_count <= bit_count - 1'b1;
          end
        end
        
        ADDR: begin
          sdata <= address[bit_count];
          parity <= parity ^ address[bit_count];
          if (bit_count == 0) begin
            state <= is_write ? DATA : PARITY;
            bit_count <= 4'd7;
          end else begin
            bit_count <= bit_count - 1'b1;
          end
        end
        
        DATA: begin
          sdata <= write_data[bit_count];
          parity <= parity ^ write_data[bit_count];
          if (bit_count == 0) begin
            state <= PARITY;
          end else begin
            bit_count <= bit_count - 1'b1;
          end
        end
        
        PARITY: begin
          sdata <= parity;
          state <= END;
        end
        
        END: begin
          sdata <= 1'b1;
          sclk <= 1'b1;
          busy <= 1'b0;
          done <= 1'b1;
          state <= IDLE;
        end
        
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end
  
  // SCLK逻辑（每个状态周期中翻转）
  always @(posedge clk) begin
    if (state != IDLE && state != END) begin
      sclk <= ~sclk;
    end
  end
endmodule