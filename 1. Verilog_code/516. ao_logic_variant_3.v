module ao_logic_pipelined_axi (
    input clk,
    input rst_n,
    
    // AXI-Stream Slave Interface
    input s_axis_tvalid,
    output reg s_axis_tready,
    input [3:0] s_axis_tdata,
    
    // AXI-Stream Master Interface
    output reg m_axis_tvalid,
    input m_axis_tready,
    output reg [0:0] m_axis_tdata
);

// Internal pipeline registers
reg [3:0] data_r;
reg and1_r, and2_r, and3_r, and4_r;
reg or1_r, or2_r;
reg result_r;

// Input stage with AXI-Stream handshake
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s_axis_tready <= 1'b1;
        data_r <= 4'b0;
    end else begin
        if (s_axis_tvalid && s_axis_tready) begin
            data_r <= s_axis_tdata;
            s_axis_tready <= 1'b0;
        end else if (!s_axis_tvalid) begin
            s_axis_tready <= 1'b1;
        end
    end
end

// Stage 2: AND operations
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        and1_r <= 1'b0;
        and2_r <= 1'b0;
        and3_r <= 1'b0;
        and4_r <= 1'b0;
    end else begin
        and1_r <= data_r[3];
        and2_r <= data_r[2];
        and3_r <= data_r[1];
        and4_r <= data_r[0];
    end
end

// Stage 3: OR operations
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        or1_r <= 1'b0;
        or2_r <= 1'b0;
    end else begin
        or1_r <= and1_r & and2_r;
        or2_r <= and3_r & and4_r;
    end
end

// Output stage with AXI-Stream handshake
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tdata <= 1'b0;
        result_r <= 1'b0;
    end else begin
        result_r <= or1_r | or2_r;
        
        if (!m_axis_tvalid || m_axis_tready) begin
            m_axis_tvalid <= 1'b1;
            m_axis_tdata <= result_r;
        end
    end
end

endmodule