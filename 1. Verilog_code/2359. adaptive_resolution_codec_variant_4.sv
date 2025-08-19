//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module adaptive_resolution_codec (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Core Interface
    output reg [15:0] pixel_out,
    output reg out_valid
);

    // Memory-mapped registers
    reg [23:0] pixel_in_reg;           // 0x00: Pixel input data
    reg [1:0] resolution_mode_reg;     // 0x04: Resolution mode
    reg data_valid_reg;                // 0x08[0]: Data valid flag
    reg line_end_reg;                  // 0x08[1]: Line end flag
    reg frame_end_reg;                 // 0x08[2]: Frame end flag
    reg [15:0] pixel_out_reg;          // 0x0C: Output pixel data (read-only)
    reg out_valid_reg;                 // 0x10[0]: Output valid flag (read-only)
    reg [31:0] status_reg;             // 0x14: Status register (read-only)
    
    // Internal signals from registers to core
    wire [23:0] pixel_in;
    wire [1:0] resolution_mode;
    wire data_valid, line_end, frame_end;
    
    // Assign core inputs from registers
    assign pixel_in = pixel_in_reg;
    assign resolution_mode = resolution_mode_reg;
    assign data_valid = data_valid_reg;
    assign line_end = line_end_reg;
    assign frame_end = frame_end_reg;
    
    // AXI write states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // AXI read states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;

    // AXI state registers
    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [31:0] awaddr_reg;
    reg [31:0] araddr_reg;
    
    // Pipeline Stage 1: Input capture and counter management
    reg [1:0] x_cnt_s1, y_cnt_s1;
    reg [23:0] pixel_in_s1;
    reg [1:0] resolution_mode_s1;
    reg data_valid_s1, line_end_s1, frame_end_s1;
    
    // Pipeline Stage 2: Accumulation logic
    reg [1:0] x_cnt_s2, y_cnt_s2;
    reg [23:0] pixel_sum_r_s2, pixel_sum_g_s2, pixel_sum_b_s2;
    reg [3:0] pixel_count_s2;
    reg [23:0] pixel_in_s2;
    reg [1:0] resolution_mode_s2;
    reg data_valid_s2;
    reg accum_valid_s2;
    
    // Pipeline Stage 3: Averaging and output generation
    reg [23:0] pixel_sum_r_s3, pixel_sum_g_s3, pixel_sum_b_s3;
    reg [23:0] pixel_in_s3;
    reg [1:0] resolution_mode_s3;
    reg [3:0] pixel_count_s3;
    reg output_ready_s3;

    // AXI4-Lite Write Transaction Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            awaddr_reg <= 32'h0;
            
            // Initialize registers
            pixel_in_reg <= 24'h0;
            resolution_mode_reg <= 2'h0;
            data_valid_reg <= 1'b0;
            line_end_reg <= 1'b0;
            frame_end_reg <= 1'b0;
        end else begin
            // Auto-clear control signals after each transaction
            if (data_valid_reg) data_valid_reg <= 1'b0;
            if (line_end_reg) line_end_reg <= 1'b0;
            if (frame_end_reg) frame_end_reg <= 1'b0;
            
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid && s_axil_awready) begin
                        awaddr_reg <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00;  // OKAY response
                        write_state <= WRITE_RESP;
                        
                        // Write to appropriate register based on address
                        case (awaddr_reg[7:0])
                            8'h00: pixel_in_reg <= s_axil_wdata[23:0];
                            8'h04: resolution_mode_reg <= s_axil_wdata[1:0];
                            8'h08: begin
                                data_valid_reg <= s_axil_wdata[0];
                                line_end_reg <= s_axil_wdata[1];
                                frame_end_reg <= s_axil_wdata[2];
                            end
                            default: begin
                                // Write to read-only register or undefined address
                                s_axil_bresp <= 2'b10;  // SLVERR response
                            end
                        endcase
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        s_axil_awready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end

    // AXI4-Lite Read Transaction Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            araddr_reg <= 32'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid && s_axil_arready) begin
                        araddr_reg <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00;  // OKAY response
                    
                    // Read from appropriate register based on address
                    case (araddr_reg[7:0])
                        8'h00: s_axil_rdata <= {8'h0, pixel_in_reg};
                        8'h04: s_axil_rdata <= {30'h0, resolution_mode_reg};
                        8'h08: s_axil_rdata <= {29'h0, frame_end_reg, line_end_reg, data_valid_reg};
                        8'h0C: s_axil_rdata <= {16'h0, pixel_out_reg};
                        8'h10: s_axil_rdata <= {31'h0, out_valid_reg};
                        8'h14: s_axil_rdata <= status_reg;
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= 2'b10;  // SLVERR response
                        end
                    endcase
                    
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

    // Status register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'h0;
            pixel_out_reg <= 16'h0;
            out_valid_reg <= 1'b0;
        end else begin
            status_reg <= {16'h0, 4'h0, pixel_count_s3, 2'h0, y_cnt_s1, 2'h0, x_cnt_s1, 1'b0, out_valid, 1'b0, data_valid};
            pixel_out_reg <= pixel_out;
            out_valid_reg <= out_valid;
        end
    end

    // Original core logic - Stage 1: Input processing and counter management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt_s1 <= 2'd0;
            y_cnt_s1 <= 2'd0;
            pixel_in_s1 <= 24'd0;
            resolution_mode_s1 <= 2'd0;
            data_valid_s1 <= 1'b0;
            line_end_s1 <= 1'b0;
            frame_end_s1 <= 1'b0;
        end else begin
            // Register inputs
            pixel_in_s1 <= pixel_in;
            resolution_mode_s1 <= resolution_mode;
            data_valid_s1 <= data_valid;
            line_end_s1 <= line_end;
            frame_end_s1 <= frame_end;
            
            if (frame_end) begin
                x_cnt_s1 <= 2'd0;
                y_cnt_s1 <= 2'd0;
            end else if (line_end) begin
                x_cnt_s1 <= 2'd0;
                y_cnt_s1 <= (y_cnt_s1 == 2'd3) ? 2'd0 : y_cnt_s1 + 2'd1;
            end else if (data_valid) begin
                x_cnt_s1 <= (x_cnt_s1 == 2'd3) ? 2'd0 : x_cnt_s1 + 2'd1;
            end
        end
    end
    
    // Stage 2: Accumulation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt_s2 <= 2'd0;
            y_cnt_s2 <= 2'd0;
            pixel_sum_r_s2 <= 24'd0;
            pixel_sum_g_s2 <= 24'd0;
            pixel_sum_b_s2 <= 24'd0;
            pixel_count_s2 <= 4'd0;
            pixel_in_s2 <= 24'd0;
            resolution_mode_s2 <= 2'd0;
            data_valid_s2 <= 1'b0;
            accum_valid_s2 <= 1'b0;
        end else begin
            // Pass through pipeline registers
            x_cnt_s2 <= x_cnt_s1;
            y_cnt_s2 <= y_cnt_s1;
            pixel_in_s2 <= pixel_in_s1;
            resolution_mode_s2 <= resolution_mode_s1;
            data_valid_s2 <= data_valid_s1;
            accum_valid_s2 <= 1'b0;
            
            if (data_valid_s1) begin
                case (resolution_mode_s1)
                    2'b00: begin // Full resolution - just pass through
                        accum_valid_s2 <= 1'b1;
                    end
                    
                    2'b01: begin // Half resolution (2x2 averaging)
                        if (y_cnt_s1[0] == 1'b0 && x_cnt_s1[0] == 1'b0) begin
                            pixel_sum_r_s2 <= pixel_in_s1[23:16];
                            pixel_sum_g_s2 <= pixel_in_s1[15:8];
                            pixel_sum_b_s2 <= pixel_in_s1[7:0];
                            pixel_count_s2 <= 4'd1;
                        end else begin
                            pixel_sum_r_s2 <= pixel_sum_r_s2 + pixel_in_s1[23:16];
                            pixel_sum_g_s2 <= pixel_sum_g_s2 + pixel_in_s1[15:8];
                            pixel_sum_b_s2 <= pixel_sum_b_s2 + pixel_in_s1[7:0];
                            pixel_count_s2 <= pixel_count_s2 + 4'd1;
                            
                            if (pixel_count_s2 == 4'd3) begin
                                accum_valid_s2 <= 1'b1;
                                pixel_count_s2 <= 4'd0;
                            end
                        end
                    end
                    
                    2'b10: begin // Quarter resolution (4x4 averaging)
                        if (y_cnt_s1 == 2'd0 && x_cnt_s1 == 2'd0) begin
                            pixel_sum_r_s2 <= pixel_in_s1[23:16];
                            pixel_sum_g_s2 <= pixel_in_s1[15:8];
                            pixel_sum_b_s2 <= pixel_in_s1[7:0];
                            pixel_count_s2 <= 4'd1;
                        end else begin
                            pixel_sum_r_s2 <= pixel_sum_r_s2 + pixel_in_s1[23:16];
                            pixel_sum_g_s2 <= pixel_sum_g_s2 + pixel_in_s1[15:8];
                            pixel_sum_b_s2 <= pixel_sum_b_s2 + pixel_in_s1[7:0];
                            pixel_count_s2 <= pixel_count_s2 + 4'd1;
                            
                            if (pixel_count_s2 == 4'd15) begin
                                accum_valid_s2 <= 1'b1;
                                pixel_count_s2 <= 4'd0;
                            end
                        end
                    end
                    
                    default: begin // Pass through
                        accum_valid_s2 <= 1'b1;
                    end
                endcase
            end
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_sum_r_s3 <= 24'd0;
            pixel_sum_g_s3 <= 24'd0;
            pixel_sum_b_s3 <= 24'd0;
            pixel_in_s3 <= 24'd0;
            resolution_mode_s3 <= 2'd0;
            pixel_count_s3 <= 4'd0;
            output_ready_s3 <= 1'b0;
            pixel_out <= 16'd0;
            out_valid <= 1'b0;
        end else begin
            // Register pipeline values
            pixel_sum_r_s3 <= pixel_sum_r_s2;
            pixel_sum_g_s3 <= pixel_sum_g_s2;
            pixel_sum_b_s3 <= pixel_sum_b_s2;
            pixel_in_s3 <= pixel_in_s2;
            resolution_mode_s3 <= resolution_mode_s2;
            pixel_count_s3 <= pixel_count_s2;
            output_ready_s3 <= accum_valid_s2;
            
            // Default output
            out_valid <= 1'b0;
            
            if (output_ready_s3) begin
                case (resolution_mode_s3)
                    2'b00: begin // Full resolution
                        pixel_out <= {pixel_in_s3[23:19], pixel_in_s3[15:10], pixel_in_s3[7:3]};
                        out_valid <= 1'b1;
                    end
                    
                    2'b01: begin // Half resolution (2x2 averaging)
                        pixel_out <= {pixel_sum_r_s3[9:5] + pixel_in_s3[23:19], 
                                     pixel_sum_g_s3[9:4] + pixel_in_s3[15:10], 
                                     pixel_sum_b_s3[9:5] + pixel_in_s3[7:3]};
                        out_valid <= 1'b1;
                    end
                    
                    2'b10: begin // Quarter resolution (4x4 averaging)
                        pixel_out <= {pixel_sum_r_s3[11:7] + pixel_in_s3[23:19], 
                                     pixel_sum_g_s3[11:6] + pixel_in_s3[15:10], 
                                     pixel_sum_b_s3[11:7] + pixel_in_s3[7:3]};
                        out_valid <= 1'b1;
                    end
                    
                    default: begin // Pass through
                        pixel_out <= {pixel_in_s3[23:19], pixel_in_s3[15:10], pixel_in_s3[7:3]};
                        out_valid <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule