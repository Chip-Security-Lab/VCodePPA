module cam_1 (
    input wire clk,
    input wire rst,
    
    // AXI-Stream Slave Interface
    input wire [31:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    input wire s_axis_tlast,
    
    // AXI-Stream Master Interface
    output reg [31:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);

    // Internal signals
    reg [7:0] store_data;
    reg match_flag;
    reg [7:0] data_in_reg;
    
    // Command codes (embedded in upper bits of tdata)
    localparam CMD_WRITE_DATA = 8'h01;
    localparam CMD_WRITE_DATAIN = 8'h02;
    localparam CMD_READ_DATA = 8'h03;
    localparam CMD_READ_DATAIN = 8'h04;
    localparam CMD_READ_STATUS = 8'h05;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam RESPOND = 2'b10;
    localparam WAIT_READY = 2'b11;
    
    reg [1:0] state;
    reg [7:0] cmd_type;
    reg read_pending;
    reg [31:0] read_data;
    
    // Process input transactions and generate output
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            s_axis_tready <= 1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 32'b0;
            m_axis_tlast <= 1'b0;
            store_data <= 8'b0;
            data_in_reg <= 8'b0;
            match_flag <= 1'b0;
            read_pending <= 1'b0;
            cmd_type <= 8'b0;
            read_data <= 32'b0;
        end else begin
            // Update match_flag on every clock cycle
            match_flag <= (store_data == data_in_reg);
            
            case (state)
                IDLE: begin
                    // Ready to accept new data
                    s_axis_tready <= 1'b1;
                    
                    if (s_axis_tvalid && s_axis_tready) begin
                        // Latch command and data
                        cmd_type <= s_axis_tdata[31:24];
                        state <= PROCESS;
                        s_axis_tready <= 1'b0;
                    end
                end
                
                PROCESS: begin
                    case (cmd_type)
                        CMD_WRITE_DATA: begin
                            store_data <= s_axis_tdata[7:0];
                            state <= RESPOND;
                            read_pending <= 1'b0;
                        end
                        
                        CMD_WRITE_DATAIN: begin
                            data_in_reg <= s_axis_tdata[7:0];
                            state <= RESPOND;
                            read_pending <= 1'b0;
                        end
                        
                        CMD_READ_DATA: begin
                            read_data <= {24'b0, store_data};
                            state <= RESPOND;
                            read_pending <= 1'b1;
                        end
                        
                        CMD_READ_DATAIN: begin
                            read_data <= {24'b0, data_in_reg};
                            state <= RESPOND;
                            read_pending <= 1'b1;
                        end
                        
                        CMD_READ_STATUS: begin
                            read_data <= {31'b0, match_flag};
                            state <= RESPOND;
                            read_pending <= 1'b1;
                        end
                        
                        default: begin
                            // Invalid command
                            read_data <= 32'hFFFFFFFF; // Error indicator
                            state <= RESPOND;
                            read_pending <= 1'b1;
                        end
                    endcase
                end
                
                RESPOND: begin
                    if (read_pending) begin
                        // For read operations, send response
                        m_axis_tdata <= read_data;
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= 1'b1;  // Mark end of transaction
                        state <= WAIT_READY;
                    end else begin
                        // For write operations, just acknowledge
                        m_axis_tdata <= {cmd_type, 24'h0};  // Echo command
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast <= 1'b1;  // Mark end of transaction
                        state <= WAIT_READY;
                    end
                end
                
                WAIT_READY: begin
                    if (m_axis_tready && m_axis_tvalid) begin
                        // Transaction complete
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule