import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { FileText, Send, CheckCircle, Home } from "lucide-react";

function ReportForm({ addIncident }) {
  const [text, setText] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = (e) => {
    e.preventDefault();
    if (text.trim()) {
      addIncident(text);
      setSubmitted(true);
      setText("");
      setTimeout(() => setSubmitted(false), 3000);
    }
  };

  return (
    <div className="page-container center-content">
      <div className="card report-card">
        <header className="report-header flex-header">
           <div className="header-text">
            <div className="auth-icon-badge">
              <FileText size={24} />
            </div>
            <h2>Report an Incident</h2>
            <p className="subtitle">Provide details about the situation for immediate classification and response.</p>
           </div>
           <Link to="/" className="btn btn-outline btn-sm back-btn-top">
              <Home size={18} />
              <span>Back to Home</span>
           </Link>
        </header>

        {submitted ? (
          <div className="success-alert pulse-bg">
            <CheckCircle size={24} />
            <span>Report submitted successfully. Our team is monitoring.</span>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="report-form">
            <div className="form-group">
              <label htmlFor="incident-desc">Incident Description</label>
              <textarea
                id="incident-desc"
                className="form-control"
                placeholder="Describe what is happening (e.g., 'Emergency: I am being followed near Central Park')"
                value={text}
                onChange={(e) => setText(e.target.value)}
                rows="5"
                required
              ></textarea>
            </div>
            <div className="report-actions">
              <button type="submit" className="btn btn-primary btn-block btn-lg">
                <Send size={18} />
                Submit Report
              </button>
              <button type="button" className="btn btn-outline btn-block" onClick={() => navigate("/")}>
                Cancel and Go Back
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

export default ReportForm;