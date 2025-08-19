//SystemVerilog
module adaptive_crossbar (
    input wire clk, rst,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
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
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Data processing outputs
    output reg valid_out,
    output reg [31:0] data_out
);
    // Internal registers
    reg [31:0] data_in_reg;
    reg [1:0] mode_reg;
    reg [7:0] sel_reg;
    reg update_config_reg;
    reg valid_in_reg;
    
    // Pipeline stage signals
    reg valid_stage1, valid_stage2;
    reg [31:0] data_in_stage1;
    reg [1:0] mode_stage1, mode_stage2;
    
    // Configuration registers for different modes
    reg [1:0] config_sel[0:3][0:3]; // [mode][output]
    
    // Pipeline registers for intermediate results
    reg [7:0] selected_segments_stage2 [0:3];
    
    // AXI4-Lite control registers - memory mapped
    localparam ADDR_DATA_IN     = 32'h0000;
    localparam ADDR_MODE        = 32'h0004;
    localparam ADDR_SEL         = 32'h0008;
    localparam ADDR_UPDATE_CFG  = 32'h000C;
    localparam ADDR_VALID_IN    = 32'h0010;
    localparam ADDR_DATA_OUT    = 32'h0014;
    localparam ADDR_VALID_OUT   = 32'h0018;
    
    // AXI4-Lite write transaction states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state;
    reg [31:0] write_addr;
    
    // AXI4-Lite read transaction states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    reg [31:0] read_addr;
    
    // AXI4-Lite write channel logic
    always @(posedge clk) begin
        if (rst) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_addr <= 32'h0;
            data_in_reg <= 32'h0;
            mode_reg <= 2'b0;
            sel_reg <= 8'h0;
            update_config_reg <= 1'b0;
            valid_in_reg <= 1'b0;
        end
        else begin
            // Default values
            update_config_reg <= 1'b0; // Auto-clear update_config after one cycle
            
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr;
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                        
                        // Write to appropriate register based on address
                        case (write_addr)
                            ADDR_DATA_IN: data_in_reg <= s_axil_wdata;
                            ADDR_MODE: mode_reg <= s_axil_wdata[1:0];
                            ADDR_SEL: sel_reg <= s_axil_wdata[7:0];
                            ADDR_UPDATE_CFG: update_config_reg <= s_axil_wdata[0];
                            ADDR_VALID_IN: valid_in_reg <= s_axil_wdata[0];
                            default: begin /* Do nothing */ end
                        endcase
                        
                        write_state <= WRITE_RESP;
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
    
    // AXI4-Lite read channel logic
    always @(posedge clk) begin
        if (rst) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            read_addr <= 32'h0;
        end
        else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                    
                    // Read from appropriate register based on address
                    case (read_addr)
                        ADDR_DATA_IN: s_axil_rdata <= data_in_reg;
                        ADDR_MODE: s_axil_rdata <= {30'b0, mode_reg};
                        ADDR_SEL: s_axil_rdata <= {24'b0, sel_reg};
                        ADDR_UPDATE_CFG: s_axil_rdata <= {31'b0, update_config_reg};
                        ADDR_VALID_IN: s_axil_rdata <= {31'b0, valid_in_reg};
                        ADDR_DATA_OUT: s_axil_rdata <= data_out;
                        ADDR_VALID_OUT: s_axil_rdata <= {31'b0, valid_out};
                        default: s_axil_rdata <= 32'h0;
                    endcase
                    
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
    
    // Configuration update logic - same as original but using internal registers
    always @(posedge clk) begin
        if (rst) begin
            // Initialize configurations (default 1:1 mapping)
            config_sel[0][0] <= 2'd0; config_sel[1][0] <= 2'd0; 
            config_sel[2][0] <= 2'd0; config_sel[3][0] <= 2'd0;
            
            config_sel[0][1] <= 2'd1; config_sel[1][1] <= 2'd1; 
            config_sel[2][1] <= 2'd1; config_sel[3][1] <= 2'd1;
            
            config_sel[0][2] <= 2'd2; config_sel[1][2] <= 2'd2; 
            config_sel[2][2] <= 2'd2; config_sel[3][2] <= 2'd2;
            
            config_sel[0][3] <= 2'd3; config_sel[1][3] <= 2'd3; 
            config_sel[2][3] <= 2'd3; config_sel[3][3] <= 2'd3;
        end else if (update_config_reg) begin
            // Update configuration for current mode
            config_sel[mode_reg][0] <= sel_reg[1:0];
            config_sel[mode_reg][1] <= sel_reg[3:2];
            config_sel[mode_reg][2] <= sel_reg[5:4];
            config_sel[mode_reg][3] <= sel_reg[7:6];
        end
    end
    
    // Split data into segments (combinational)
    wire [7:0] data_segments[0:3];
    assign data_segments[0] = data_in_reg[7:0];
    assign data_segments[1] = data_in_reg[15:8];
    assign data_segments[2] = data_in_reg[23:16];
    assign data_segments[3] = data_in_reg[31:24];
    
    // Pipeline Stage 1: Register input data and control signals
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= 32'h00000000;
            mode_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in_reg;
            mode_stage1 <= mode_reg;
            valid_stage1 <= valid_in_reg;
        end
    end
    
    // Pipeline Stage 2: Select segments based on configuration
    always @(posedge clk) begin
        if (rst) begin
            selected_segments_stage2[0] <= 8'h00;
            selected_segments_stage2[1] <= 8'h00;
            selected_segments_stage2[2] <= 8'h00;
            selected_segments_stage2[3] <= 8'h00;
            mode_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            // Extract segments from data_in_stage1 based on config_sel for current mode
            selected_segments_stage2[0] <= data_segments[config_sel[mode_stage1][0]];
            selected_segments_stage2[1] <= data_segments[config_sel[mode_stage1][1]];
            selected_segments_stage2[2] <= data_segments[config_sel[mode_stage1][2]];
            selected_segments_stage2[3] <= data_segments[config_sel[mode_stage1][3]];
            mode_stage2 <= mode_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Assemble output data
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 32'h00000000;
            valid_out <= 1'b0;
        end else begin
            data_out[7:0] <= selected_segments_stage2[0];
            data_out[15:8] <= selected_segments_stage2[1];
            data_out[23:16] <= selected_segments_stage2[2];
            data_out[31:24] <= selected_segments_stage2[3];
            valid_out <= valid_stage2;
        end
    end
endmodule