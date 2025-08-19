//SystemVerilog
module seq_detector_0110_axi_stream (
    input wire clk,
    input wire rst_n,
    // AXI-Stream Interface
    input wire [3:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output reg s_axis_tready,
    output reg [3:0] m_axis_tdata,
    output reg m_axis_tvalid,
    input wire m_axis_tready,
    output reg m_axis_tlast
);

    parameter S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] state, next_state;
    reg [1:0] booth_a, booth_b;
    reg [3:0] booth_p;
    reg [1:0] booth_counter;
    reg booth_done;
    reg [3:0] data_buffer;
    reg data_valid;
    reg processing;
    
    // AXI-Stream handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            data_valid <= 1'b0;
            processing <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                data_buffer <= s_axis_tdata;
                data_valid <= 1'b1;
                s_axis_tready <= 1'b0;
                processing <= 1'b1;
            end
            
            if (processing && booth_done) begin
                m_axis_tdata <= booth_p;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1;
                if (m_axis_tready) begin
                    m_axis_tvalid <= 1'b0;
                    m_axis_tlast <= 1'b0;
                    s_axis_tready <= 1'b1;
                    processing <= 1'b0;
                end
            end
        end
    end
    
    // State register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S0;
        end else if (data_valid) begin
            state <= next_state;
        end
    end
    
    // Booth multiplier initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_p <= 4'b0;
            booth_counter <= 2'b0;
            booth_done <= 1'b0;
        end else if (data_valid && !booth_done && booth_counter == 2'b00) begin
            booth_a <= {1'b0, data_buffer[0]};
            booth_b <= {1'b0, state[0]};
            booth_p <= 4'b0;
            booth_counter <= booth_counter + 1;
        end
    end
    
    // Booth multiplier step 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_a <= 2'b0;
        end else if (data_valid && !booth_done && booth_counter == 2'b01) begin
            if (booth_a[0] == 1'b1)
                booth_p <= booth_p + {2'b0, booth_b};
            booth_a <= booth_a >> 1;
            booth_counter <= booth_counter + 1;
        end
    end
    
    // Booth multiplier step 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_done <= 1'b0;
        end else if (data_valid && !booth_done && booth_counter == 2'b10) begin
            if (booth_a[0] == 1'b1)
                booth_p <= booth_p + {2'b0, booth_b};
            booth_done <= 1'b1;
        end
    end
    
    // Next state and output logic
    always @(*) begin
        case (state)
            S0: next_state = data_buffer[0] ? S1 : S0;
            S1: next_state = data_buffer[0] ? S1 : S2;
            S2: next_state = data_buffer[0] ? S3 : S0;
            S3: next_state = data_buffer[0] ? S1 : S2;
            default: next_state = S0;
        endcase
    end
endmodule