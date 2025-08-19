module eth_pause_frame_gen (
    input wire clk,
    input wire reset,
    input wire generate_pause,
    input wire [15:0] pause_time,
    input wire [47:0] local_mac,
    output reg [7:0] tx_data,
    output reg tx_en,
    output reg frame_complete
);
    // Multicast MAC address for PAUSE frames
    localparam [47:0] PAUSE_ADDR = 48'h010000C28001;
    localparam [15:0] MAC_CONTROL = 16'h8808;
    localparam [15:0] PAUSE_OPCODE = 16'h0001;
    
    reg [4:0] state;
    reg [3:0] counter;
    
    localparam IDLE = 5'd0, PREAMBLE = 5'd1, SFD = 5'd2;
    localparam DST_ADDR = 5'd3, SRC_ADDR = 5'd4, LENGTH = 5'd5;
    localparam OPCODE = 5'd6, PAUSE_PARAM = 5'd7, PAD = 5'd8, FCS = 5'd9;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            counter <= 4'd0;
            tx_en <= 1'b0;
            tx_data <= 8'd0;
            frame_complete <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (generate_pause) begin
                        state <= PREAMBLE;
                        counter <= 4'd0;
                        tx_en <= 1'b1;
                        frame_complete <= 1'b0;
                    end else begin
                        tx_en <= 1'b0;
                    end
                end
                
                PREAMBLE: begin
                    tx_data <= 8'h55;
                    if (counter == 4'd6) begin
                        state <= SFD;
                        counter <= 4'd0;
                    end else
                        counter <= counter + 1'b1;
                end
                
                SFD: begin
                    tx_data <= 8'hD5;
                    state <= DST_ADDR;
                    counter <= 4'd0;
                end
                
                DST_ADDR: begin
                    case (counter)
                        4'd0: tx_data <= PAUSE_ADDR[47:40];
                        4'd1: tx_data <= PAUSE_ADDR[39:32];
                        4'd2: tx_data <= PAUSE_ADDR[31:24];
                        4'd3: tx_data <= PAUSE_ADDR[23:16];
                        4'd4: tx_data <= PAUSE_ADDR[15:8];
                        default: tx_data <= PAUSE_ADDR[7:0];
                    endcase
                    
                    if (counter == 4'd5) begin
                        state <= SRC_ADDR;
                        counter <= 4'd0;
                    end else
                        counter <= counter + 1'b1;
                end
                
                SRC_ADDR: begin
                    case (counter)
                        4'd0: tx_data <= local_mac[47:40];
                        4'd1: tx_data <= local_mac[39:32];
                        4'd2: tx_data <= local_mac[31:24];
                        4'd3: tx_data <= local_mac[23:16];
                        4'd4: tx_data <= local_mac[15:8];
                        default: tx_data <= local_mac[7:0];
                    endcase
                    
                    if (counter == 4'd5) begin
                        state <= LENGTH;
                        counter <= 4'd0;
                    end else
                        counter <= counter + 1'b1;
                end
                
                LENGTH: begin
                    if (counter == 4'd0) begin
                        tx_data <= MAC_CONTROL[15:8];
                        counter <= counter + 1'b1;
                    end else begin
                        tx_data <= MAC_CONTROL[7:0];
                        state <= OPCODE;
                        counter <= 4'd0;
                    end
                end
                
                OPCODE: begin
                    if (counter == 4'd0) begin
                        tx_data <= PAUSE_OPCODE[15:8];
                        counter <= counter + 1'b1;
                    end else begin
                        tx_data <= PAUSE_OPCODE[7:0];
                        state <= PAUSE_PARAM;
                        counter <= 4'd0;
                    end
                end
                
                PAUSE_PARAM: begin
                    if (counter == 4'd0) begin
                        tx_data <= pause_time[15:8];
                        counter <= counter + 1'b1;
                    end else begin
                        tx_data <= pause_time[7:0];
                        state <= PAD;
                        counter <= 4'd0;
                    end
                end
                
                PAD: begin
                    tx_data <= 8'h00;
                    if (counter == 4'd9) begin
                        state <= FCS;
                        counter <= 4'd0;
                    end else
                        counter <= counter + 1'b1;
                end
                
                FCS: begin
                    // Simplified FCS - in a real design this would be calculated
                    tx_data <= 8'hAA;
                    if (counter == 4'd3) begin
                        state <= IDLE;
                        frame_complete <= 1'b1;
                        tx_en <= 1'b0;
                    end else
                        counter <= counter + 1'b1;
                end
            endcase
        end
    end
endmodule